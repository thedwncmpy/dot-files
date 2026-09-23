#!/usr/bin/env python3
"""A small, Vim-like tmux session manager for display-popup."""

import copy
import curses
from dataclasses import dataclass
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import termios
from typing import Optional


ORDER_FILE = Path(__file__).with_name("session-order.json")


@dataclass
class Session:
    id: Optional[str]
    name: str
    windows: int = 1


def tmux(*args):
    result = subprocess.run(["tmux", *args], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "tmux command failed")
    return result.stdout.strip()


class SessionStore:
    def __init__(self):
        self.original = {}

    def live_sessions(self):
        rows = []
        output = tmux("list-sessions", "-F", "#{session_id}\t#{session_name}\t#{session_windows}")
        for line in output.splitlines():
            fields = line.split("\t", 2)
            if len(fields) != 3:
                raise RuntimeError("Could not read tmux session: " + line)
            rows.append(Session(fields[0], fields[1], int(fields[2])))
        return rows

    def load_order(self):
        try:
            names = json.loads(ORDER_FILE.read_text())
            return names if isinstance(names, list) else []
        except (FileNotFoundError, ValueError):
            return []

    def reload(self):
        rows = self.live_sessions()
        order = {name: index for index, name in enumerate(self.load_order()) if isinstance(name, str)}
        rows.sort(key=lambda row: order.get(row.name, len(order)))
        self.original = {row.id: row.name for row in rows}
        return rows

    def current_id(self):
        return tmux("display-message", "-p", "#{session_id}")

    def plan(self, rows):
        if not rows:
            raise ValueError("Keep at least one session")
        ids, names = set(), set()
        for row in rows:
            row.name = row.name.strip()
            if not row.name:
                raise ValueError("Session names cannot be empty")
            if row.name in names:
                raise ValueError("Duplicate session name: " + row.name)
            names.add(row.name)
            if row.id:
                if row.id not in self.original:
                    raise ValueError("Unknown session ID: " + row.id)
                if row.id in ids:
                    raise ValueError("The same session appears twice: " + row.name)
                ids.add(row.id)
        return [Session(id, name) for id, name in self.original.items() if id not in ids]

    def write_order(self, rows):
        descriptor, temporary = tempfile.mkstemp(prefix="session-order-", dir=ORDER_FILE.parent)
        try:
            with os.fdopen(descriptor, "w") as file:
                json.dump([row.name for row in rows], file)
                file.write("\n")
            os.replace(temporary, ORDER_FILE)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

    def save(self, rows):
        removed = self.plan(rows)
        live = self.live_sessions()
        if {row.id: row.name for row in live} != self.original:
            raise RuntimeError("Sessions changed outside the picker. Press R to refresh")

        renamed = [row for row in rows if row.id and self.original[row.id] != row.name]
        used = {row.name for row in rows} | set(self.original.values())
        for index, row in enumerate(renamed + removed, 1):
            temporary = "__session_edit_{}_{}".format(os.getpid(), index)
            while temporary in used:
                temporary += "_"
            used.add(temporary)
            tmux("rename-session", "-t", row.id, temporary)
        for row in renamed:
            tmux("rename-session", "-t", row.id, row.name)
        for row in rows:
            if row.id is None:
                row.id = tmux("new-session", "-d", "-P", "-F", "#{session_id}", "-s", row.name, "-c", os.getcwd())

        # Killing the session that owns the popup closes this process, so persist first.
        self.write_order(rows)
        current = self.current_id()
        for row in removed:
            if row.id != current:
                tmux("kill-session", "-t", row.id)
        for row in removed:
            if row.id == current:
                tmux("kill-session", "-t", row.id)
                return rows
        return self.reload()


class SessionManager:
    def __init__(self, screen, store):
        self.screen = screen
        self.store = store
        self.rows = store.reload()
        self.baseline = self.signature()
        self.current = store.current_id()
        self.cursor = next((i for i, row in enumerate(self.rows) if row.id == self.current), 0)
        self.scroll = 0
        self.visual_anchor = None
        self.clipboard = []
        self.undo = []
        self.redo = []
        self.pending = ""
        self.message = "Move rows, then Ctrl-S to save and renumber"
        self.running = True
        self.screen.keypad(True)
        try:
            curses.curs_set(0)
        except curses.error:
            pass

    def signature(self):
        return [(row.id, row.name) for row in self.rows]

    def modified(self):
        return self.signature() != self.baseline

    def snapshot(self):
        return (copy.deepcopy(self.rows), self.cursor, self.visual_anchor, copy.deepcopy(self.clipboard))

    def remember(self):
        self.undo.append(self.snapshot())
        self.redo.clear()

    def restore(self, state):
        self.rows, self.cursor, self.visual_anchor, self.clipboard = copy.deepcopy(state)

    def status(self, message):
        self.message = message

    def add_text(self, row, column, text, width, style=0):
        height, columns = self.screen.getmaxyx()
        if row >= height or column >= columns or width < 1:
            return
        try:
            self.screen.addnstr(row, column, text, min(width, columns - column - 1), style)
        except curses.error:
            pass

    def draw(self):
        screen = self.screen
        screen.erase()
        height, width = screen.getmaxyx()
        if height < 7 or width < 32:
            self.add_text(0, 0, "Make the popup larger", width - 1)
            screen.refresh()
            return
        title = "Sessions" + ("  •  unsaved" if self.modified() else "")
        self.add_text(0, 1, title, width - 2, curses.A_BOLD)
        self.add_text(1, 1, "j/k select  J/K move  v block  e rename  a add  dd cut  p/P paste", width - 2)
        self.add_text(2, 1, "Ctrl-S save  Enter/1-9/0 switch  u undo  Ctrl-R redo  R refresh  q quit", width - 2)
        body_top, body_height = 3, height - 5
        if self.cursor < self.scroll:
            self.scroll = self.cursor
        if self.cursor >= self.scroll + body_height:
            self.scroll = self.cursor - body_height + 1
        for visible in range(body_height):
            index = self.scroll + visible
            if index >= len(self.rows):
                break
            row = self.rows[index]
            marker = "*" if row.id == self.current else "+" if row.id is None else " "
            count = "  {}w".format(row.windows) if row.id else "  new"
            line = "{:>2}  {} {}{}".format(index + 1, marker, row.name, count)
            selected = self.visual_anchor is not None and min(self.cursor, self.visual_anchor) <= index <= max(self.cursor, self.visual_anchor)
            style = curses.A_REVERSE if index == self.cursor or selected else 0
            self.add_text(body_top + visible, 1, line, width - 2, style)
        self.add_text(height - 2, 1, self.message, width - 2)
        screen.refresh()

    def ask(self, label, initial=""):
        height, width = self.screen.getmaxyx()
        content = list(initial)
        cursor = len(content)
        try:
            curses.curs_set(1)
        except curses.error:
            pass
        while True:
            self.screen.move(height - 2, 0)
            self.screen.clrtoeol()
            available = max(1, width - len(label) - 3)
            start = max(0, cursor - available + 1)
            self.add_text(height - 2, 1, label + "".join(content[start:]), width - 2)
            self.screen.move(height - 2, min(width - 2, len(label) + cursor - start + 1))
            self.screen.refresh()
            key = self.screen.get_wch()
            if key in ("\n", "\r", curses.KEY_ENTER):
                result = "".join(content).strip()
                break
            if key == "\x1b":
                result = None
                break
            if key in (curses.KEY_BACKSPACE, "\b", "\x7f") and cursor:
                content.pop(cursor - 1)
                cursor -= 1
            elif key == curses.KEY_DC and cursor < len(content):
                content.pop(cursor)
            elif key == curses.KEY_LEFT:
                cursor = max(0, cursor - 1)
            elif key == curses.KEY_RIGHT:
                cursor = min(len(content), cursor + 1)
            elif key in (curses.KEY_HOME, "\x01"):
                cursor = 0
            elif key in (curses.KEY_END, "\x05"):
                cursor = len(content)
            elif isinstance(key, str) and key.isprintable():
                content.insert(cursor, key)
                cursor += 1
        try:
            curses.curs_set(0)
        except curses.error:
            pass
        return result

    def confirm(self, message):
        self.status(message + "  [y: yes / n: keep editing]")
        while True:
            self.draw()
            key = self.screen.get_wch()
            if key in ("y", "Y"):
                return True
            if key in ("n", "N", "\x1b", "\x03", "\n", "\r", curses.KEY_ENTER):
                self.status("Kept unsaved edits; Ctrl-S saves, q asks to discard")
                return False

    def move_selection(self, delta):
        if self.visual_anchor is None:
            destination = self.cursor + delta
            if not 0 <= destination < len(self.rows):
                return
            self.remember()
            self.rows[self.cursor], self.rows[destination] = self.rows[destination], self.rows[self.cursor]
            self.cursor = destination
            return
        first, last = sorted((self.cursor, self.visual_anchor))
        if delta < 0 and first > 0:
            self.remember()
            self.rows[first - 1:last + 1] = self.rows[first:last + 1] + [self.rows[first - 1]]
        elif delta > 0 and last < len(self.rows) - 1:
            self.remember()
            self.rows[first:last + 2] = [self.rows[last + 1]] + self.rows[first:last + 1]
        else:
            return
        self.cursor += delta
        self.visual_anchor += delta

    def cut(self):
        if not self.rows:
            return
        first, last = sorted((self.cursor, self.visual_anchor)) if self.visual_anchor is not None else (self.cursor, self.cursor)
        self.remember()
        self.clipboard = self.rows[first:last + 1]
        del self.rows[first:last + 1]
        self.cursor = min(first, max(0, len(self.rows) - 1))
        self.visual_anchor = None
        self.status("Cut {} row(s); p/P pastes, Ctrl-S confirms deletion".format(len(self.clipboard)))

    def paste(self, above=False):
        if not self.clipboard:
            self.status("Nothing to paste")
            return
        existing = {row.id for row in self.rows if row.id}
        if any(row.id in existing for row in self.clipboard if row.id):
            self.status("That session is already in the list")
            return
        self.remember()
        index = self.cursor if above else self.cursor + 1
        if not self.rows:
            index = 0
        self.rows[index:index] = copy.deepcopy(self.clipboard)
        self.cursor = index
        self.visual_anchor = None

    def edit(self):
        if not self.rows:
            return
        value = self.ask("Rename: ", self.rows[self.cursor].name)
        if value is None:
            return
        if not value:
            self.status("Session name cannot be empty")
            return
        if value != self.rows[self.cursor].name:
            self.remember()
            self.rows[self.cursor].name = value

    def add(self, above=False):
        value = self.ask("New session: ")
        if value is None:
            return
        if not value:
            self.status("Session name cannot be empty")
            return
        self.remember()
        index = self.cursor if above else self.cursor + 1
        if not self.rows:
            index = 0
        self.rows.insert(index, Session(None, value))
        self.cursor = index
        self.visual_anchor = None

    def save(self):
        try:
            removed = self.store.plan(self.rows)
            if removed and not self.confirm("Kill session(s): " + ", ".join(row.name for row in removed) + "?"):
                self.status("Save cancelled")
                return False
            selected = self.rows[self.cursor] if self.rows else None
            self.rows = self.store.save(self.rows)
            self.baseline = self.signature()
            if selected:
                self.cursor = next((i for i, row in enumerate(self.rows) if row.id == selected.id), 0)
            self.cursor = min(self.cursor, max(0, len(self.rows) - 1))
            self.visual_anchor = None
            self.clipboard = []
            self.undo.clear()
            self.redo.clear()
            self.status("Saved; sessions numbered 1-{}".format(len(self.rows)))
            return True
        except (OSError, RuntimeError, ValueError) as error:
            self.status("Error: " + str(error))
            return False

    def switch(self, index):
        if not 0 <= index < len(self.rows):
            self.status("No session at that number")
            return
        target = self.rows[index]
        if self.modified() and not self.save():
            return
        if target.id is None:
            target = next((row for row in self.rows if row.name == target.name), None)
        if target is None or target.id is None:
            self.status("Session is no longer available")
            return
        try:
            tmux("switch-client", "-t", target.id)
            self.running = False
        except RuntimeError as error:
            self.status("Error: " + str(error))

    def refresh(self):
        if self.modified() and not self.confirm("Discard unsaved edits?"):
            return
        try:
            self.rows = self.store.reload()
            self.baseline = self.signature()
            self.cursor = min(self.cursor, max(0, len(self.rows) - 1))
            self.visual_anchor = None
            self.clipboard = []
            self.undo.clear()
            self.redo.clear()
            self.status("Sessions refreshed")
        except (OSError, RuntimeError, ValueError) as error:
            self.status("Error: " + str(error))

    def command(self):
        value = self.ask(":")
        if value is None:
            return
        if value in ("w", "write"):
            self.save()
        elif value in ("q", "quit"):
            self.quit()
        elif value in ("q!", "quit!"):
            self.running = False
        elif value.startswith("m ") or value.startswith("move "):
            try:
                destination = int(value.split()[1])
                if not 0 <= destination <= len(self.rows):
                    raise ValueError
                self.remember()
                old_position = self.cursor
                row = self.rows.pop(self.cursor)
                self.cursor = destination - (1 if old_position < destination else 0)
                self.rows.insert(self.cursor, row)
                self.visual_anchor = None
            except (IndexError, ValueError):
                self.status("Use :m N with a row number from 0 to {}".format(len(self.rows)))
        else:
            self.status("Unknown command: " + value)

    def quit(self):
        if not self.modified() or self.confirm("Discard unsaved edits and close?"):
            self.running = False

    def run(self):
        while self.running:
            self.draw()
            key = self.screen.get_wch()
            if self.pending:
                pending = self.pending
                self.pending = ""
                if pending == "d" and key == "d":
                    self.cut()
                    continue
                if pending == "c" and key in ("c", "w"):
                    self.edit()
                    continue
                if pending == "g" and key == "g":
                    self.cursor = 0
                    continue
            if key in ("j", curses.KEY_DOWN):
                self.cursor = min(len(self.rows) - 1, self.cursor + 1) if self.rows else 0
            elif key in ("k", curses.KEY_UP):
                self.cursor = max(0, self.cursor - 1)
            elif key == "G":
                self.cursor = max(0, len(self.rows) - 1)
            elif key in ("J", "K"):
                self.move_selection(1 if key == "J" else -1)
            elif key == "v":
                self.visual_anchor = None if self.visual_anchor is not None else self.cursor
            elif key in ("d", "c", "g"):
                if key == "d" and self.visual_anchor is not None:
                    self.cut()
                else:
                    self.pending = key
                    self.status(key + ": waiting for another key")
            elif key == "p":
                self.paste()
            elif key == "P":
                self.paste(above=True)
            elif key in ("e", "r"):
                self.edit()
            elif key in ("a", "o", "O"):
                self.add(above=key == "O")
            elif key == "u":
                if self.undo:
                    self.redo.append(self.snapshot())
                    self.restore(self.undo.pop())
            elif key == "\x12":
                if self.redo:
                    self.undo.append(self.snapshot())
                    self.restore(self.redo.pop())
            elif key == "\x13":
                self.save()
            elif key in ("\n", "\r", curses.KEY_ENTER):
                self.switch(self.cursor)
            elif isinstance(key, str) and key in "1234567890":
                self.switch(9 if key == "0" else int(key) - 1)
            elif key == "R":
                self.refresh()
            elif key == "q":
                self.quit()
            elif key == ":":
                self.command()
            elif key == "\x1b":
                self.visual_anchor = None
                self.pending = ""


def main():
    if not os.environ.get("TMUX"):
        raise SystemExit("Run this picker inside tmux")
    terminal = sys.stdin.fileno()
    original = termios.tcgetattr(terminal)
    settings = original.copy()
    settings[0] &= ~(termios.IXON | termios.IXOFF)
    termios.tcsetattr(terminal, termios.TCSANOW, settings)
    try:
        curses.wrapper(lambda screen: SessionManager(screen, SessionStore()).run())
    finally:
        termios.tcsetattr(terminal, termios.TCSANOW, original)


if __name__ == "__main__":
    main()

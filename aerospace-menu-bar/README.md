# AeroSpace menu bar

A native macOS menu bar app for a single display. It shows each AeroSpace workspace
as its number followed by the icons of apps with windows there. Workspaces are
separated by `|`. The active workspace number has an accent underline, and a
small white dot sits beneath the focused app icon. Multiple windows from one app produce one icon per workspace.
Click the menu bar item to switch workspaces or quit.
The underline and dot glide to their new positions when focus or layout changes.
Focus changes update from AeroSpace events; the app also polls every two seconds
for layout changes.

App icons follow their window positions in the visible workspace. The app keeps
the last observed order for each workspace after you switch away from it. Before
a workspace has been shown, its icons use app-name order because AeroSpace does
not expose the layout order of hidden workspaces.

Requires macOS 13+, Swift 5.9+, and a running AeroSpace installation.

```sh
cd ~/.config/aerospace-menu-bar
./build-app.sh
open dist/AeroSpaceMenuBar.app
```

The app refreshes every two seconds. It reads the workspaces and windows on the
focused monitor. Multi-display layouts are outside the current scope. To start
it at login, add `dist/AeroSpaceMenuBar.app` in macOS Login Items.

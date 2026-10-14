import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { renderSequence } from './renderer.mjs';

const execFileAsync = promisify(execFile);

function sequenceFromSource(source) {
  const lines = source.split(/\r?\n/).map(line => line.trim()).filter(Boolean);
  if (lines[0] !== 'sequenceDiagram') return null;
  const participants = [];
  const names = new Map();
  const messages = [];
  let numbered = false;
  for (const line of lines.slice(1)) {
    if (line.startsWith('%%')) continue;
    if (line === 'autonumber') { numbered = true; continue; }
    const participant = /^(?:participant|actor)\s+([\w.-]+)(?:\s+as\s+(.+))?$/.exec(line);
    if (participant) {
      const [, id, display] = participant;
      if (!names.has(id)) participants.push(display || id);
      names.set(id, display || id);
      continue;
    }
    const message = /^([\w.-]+?)\s*(-->>|->>|-->|->|--x|-x)\s*([\w.-]+)\s*:\s*(.+)$/.exec(line);
    if (message) {
      const [, from, , to, label] = message;
      for (const id of [from, to]) {
        if (!names.has(id)) { names.set(id, id); participants.push(id); }
      }
      messages.push({ from: names.get(from), to: names.get(to), label: numbered ? `${messages.length + 1}. ${label}` : label });
      continue;
    }
    return null;
  }
  if (!messages.length) return null;
  try { return renderSequence({ participants, messages }); }
  catch { return null; }
}

export async function terminalPreview(source, png) {
  const sequence = sequenceFromSource(source);
  if (sequence) return { text: sequence, kind: 'sequence' };
  try {
    const { stdout } = await execFileAsync('chafa', [
      '--format', 'symbols', '--colors', 'none', '--symbols', 'ascii',
      '--invert', '--size', '96x28', '--probe', 'off', png,
    ], { timeout: 5000, maxBuffer: 12000 });
    return { text: stdout.trimEnd(), kind: 'raster' };
  } catch {
    return null;
  }
}

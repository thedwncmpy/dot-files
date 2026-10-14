import { createHash } from 'node:crypto';
import { execFile } from 'node:child_process';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';
import { terminalPreview } from './terminal.mjs';

const execFileAsync = promisify(execFile);
const here = dirname(fileURLToPath(import.meta.url));
const outputDir = join(here, 'generated');
const mmdc = join(here, 'node_modules', '.bin', 'mmdc');
const browserConfig = join(here, 'puppeteer-config.json');

export async function renderMermaid(source) {
  if (typeof source !== 'string' || !source.trim()) throw new Error('source must be nonempty Mermaid text');
  if (source.length > 20000) throw new Error('source must be at most 20,000 characters');
  const hash = createHash('sha256').update(source).digest('hex').slice(0, 16);
  await mkdir(outputDir, { recursive: true });
  const stem = join(outputDir, `diagram-${hash}`);
  const input = `${stem}.mmd`;
  const svg = `${stem}.svg`;
  const png = `${stem}.png`;
  await writeFile(input, source, 'utf8');
  const options = { timeout: 30000, maxBuffer: 1024 * 1024 };
  try {
    await execFileAsync(mmdc, ['-i', input, '-o', svg, '-p', browserConfig], options);
    await execFileAsync(mmdc, ['-i', input, '-o', png, '-p', browserConfig, '-b', 'white'], options);
  } catch (error) {
    const detail = (error.stderr || error.message || '').trim();
    throw new Error(`Mermaid rendering failed: ${detail.slice(0, 600)}`);
  }
  return { input, svg, png, image: (await readFile(png)).toString('base64'), preview: await terminalPreview(source, png) };
}

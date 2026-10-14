#!/usr/bin/env node
import { renderDiagram } from './renderer.mjs';
import { renderMermaid } from './mermaid.mjs';

const tool = {
  name: 'render_diagram',
  description: 'Render a flowchart or sequence diagram as monospaced Unicode text for display directly in a Codex CLI chat. Copy the returned diagram verbatim into a text code block in your answer. Flowcharts show repeated nodes with ↩; choose short labels for readable output.',
  inputSchema: {
    type: 'object',
    properties: {
      kind: { type: 'string', enum: ['flowchart', 'sequence'] },
      nodes: { type: 'array', items: { type: 'object', properties: { id: { type: 'string' }, label: { type: 'string' } }, required: ['id', 'label'] } },
      edges: { type: 'array', items: { type: 'object', properties: { from: { type: 'string' }, to: { type: 'string' }, label: { type: 'string' } }, required: ['from', 'to'] } },
      start: { type: 'string' },
      participants: { type: 'array', items: { type: 'string' } },
      messages: { type: 'array', items: { type: 'object', properties: { from: { type: 'string' }, to: { type: 'string' }, label: { type: 'string' } }, required: ['from', 'to', 'label'] } },
    },
    required: ['kind'],
  },
};
const mermaidTool = {
  name: 'render_mermaid',
  description: 'Render Mermaid source to PNG and SVG and return a terminal preview. In Codex CLI, show the terminal preview verbatim in a plain text code block; its Mermaid renderer does not display every diagram type. Also link the PNG for full resolution. The PNG is returned as MCP image content for clients that display it. Requires local Chrome and installed dependencies.',
  inputSchema: {
    type: 'object',
    properties: { source: { type: 'string', description: 'Complete Mermaid diagram definition, such as flowchart LR, sequenceDiagram, classDiagram, or gantt.' } },
    required: ['source'],
  },
};

function reply(id, result, error) {
  if (id === undefined) return;
  process.stdout.write(JSON.stringify(error ? { jsonrpc: '2.0', id, error } : { jsonrpc: '2.0', id, result }) + '\n');
}

async function handle(message) {
  const { id, method, params } = message;
  if (method === 'initialize') return reply(id, {
    protocolVersion: '2024-11-05',
    capabilities: { tools: {} },
    serverInfo: { name: 'codex-diagrams', version: '0.1.0' },
  });
  if (method === 'notifications/initialized') return;
  if (method === 'ping') return reply(id, {});
  if (method === 'tools/list') return reply(id, { tools: [tool, mermaidTool] });
  if (method === 'tools/call') {
    try {
      if (params?.name === mermaidTool.name) {
        const result = await renderMermaid(params.arguments?.source);
        return reply(id, { content: [
          { type: 'text', text: `Terminal preview (${result.preview?.kind || 'unavailable'}):\n${result.preview?.text || 'Use the PNG link to view this diagram.'}\n\nPNG: ${result.png}\nSVG: ${result.svg}\nSource: ${result.input}\nFor Codex CLI, put the terminal preview in a plain text code block and link the PNG. Do not use a mermaid code block as the only visible diagram.` },
          { type: 'image', data: result.image, mimeType: 'image/png' },
        ] });
      }
      if (params?.name !== tool.name) return reply(id, undefined, { code: -32601, message: 'Unknown tool' });
      return reply(id, { content: [{ type: 'text', text: renderDiagram(params.arguments) }] });
    } catch (error) {
      return reply(id, { isError: true, content: [{ type: 'text', text: error.message }] });
    }
  }
  if (id !== undefined) reply(id, undefined, { code: -32601, message: 'Method not found' });
}

let buffer = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  buffer += chunk;
  let newline;
  while ((newline = buffer.indexOf('\n')) !== -1) {
    const line = buffer.slice(0, newline).trim();
    buffer = buffer.slice(newline + 1);
    if (!line) continue;
    try { void handle(JSON.parse(line)); }
    catch (error) { process.stderr.write(`Invalid MCP request: ${error.message}\n`); }
  }
});

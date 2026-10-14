import test from 'node:test';
import assert from 'node:assert/strict';
import { renderDiagram } from './renderer.mjs';

test('branches and repeated nodes stay legible', () => {
  const diagram = renderDiagram({
    kind: 'flowchart',
    nodes: [
      { id: 'request', label: 'Request' },
      { id: 'valid', label: 'Valid?' },
      { id: 'reject', label: 'Reject' },
      { id: 'auth', label: 'Authenticate' },
      { id: 'done', label: 'Done' },
    ],
    edges: [
      { from: 'request', to: 'valid' },
      { from: 'valid', to: 'reject', label: 'No' },
      { from: 'valid', to: 'auth', label: 'Yes' },
      { from: 'auth', to: 'done' },
      { from: 'reject', to: 'done' },
    ],
  });
  assert.match(diagram, /├── No → \[Reject\]/);
  assert.match(diagram, /└── Yes → \[Authenticate\]/);
  assert.match(diagram, /\[Done\] ↩/);
});

test('sequence arrows point toward the recipient', () => {
  const diagram = renderDiagram({ kind: 'sequence', participants: ['Client', 'API'], messages: [
    { from: 'Client', to: 'API', label: 'request' },
    { from: 'API', to: 'Client', label: 'response' },
  ] });
  assert.match(diagram, /├─+▶/);
  assert.match(diagram, /◀─+┤/);
});

test('unknown graph references are rejected', () => {
  assert.throws(() => renderDiagram({ kind: 'flowchart', nodes: [{ id: 'a', label: 'A' }], edges: [{ from: 'a', to: 'missing' }] }), /unknown node/);
});

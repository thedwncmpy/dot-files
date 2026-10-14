import test from 'node:test';
import assert from 'node:assert/strict';
import { terminalPreview } from './terminal.mjs';

test('Mermaid sequence source becomes a visible terminal diagram', async () => {
  const source = `sequenceDiagram
    autonumber
    participant Browser
    participant API
    participant Database
    Browser->>API: GET /users/42
    API->>Database: SELECT user WHERE id = 42
    Database-->>API: User record
    API-->>Browser: 200 OK + user JSON`;
  const result = await terminalPreview(source, 'unused.png');
  assert.equal(result.kind, 'sequence');
  assert.match(result.text, /Browser\s+API\s+Database/);
  assert.match(result.text, /1\. GET \/users\/42/);
  assert.match(result.text, /3\. User record/);
  assert.doesNotMatch(result.text, /Database-/);
});

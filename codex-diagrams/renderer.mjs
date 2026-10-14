function clean(value, name) {
  if (typeof value !== 'string' || !value.trim()) throw new Error(`${name} must be a nonempty string`);
  const result = value.trim().replace(/[\u0000-\u001f\u007f-\u009f]+/g, ' ').replace(/\s+/g, ' ');
  if (result.length > 80) throw new Error(`${name} must be at most 80 characters`);
  return result;
}

function limit(items, name, max = 30) {
  if (!Array.isArray(items) || !items.length || items.length > max) {
    throw new Error(`${name} must contain 1 to ${max} items`);
  }
  return items;
}

export function renderFlowchart(input) {
  const nodes = limit(input.nodes, 'nodes').map((node, i) => ({
    id: clean(node?.id, `nodes[${i}].id`),
    label: clean(node?.label, `nodes[${i}].label`),
  }));
  const byId = new Map(nodes.map(node => [node.id, node]));
  if (byId.size !== nodes.length) throw new Error('node IDs must be unique');
  const edges = Array.isArray(input.edges) ? input.edges : [];
  if (edges.length > 60) throw new Error('edges must contain at most 60 items');
  const outgoing = new Map(nodes.map(node => [node.id, []]));
  const incoming = new Map(nodes.map(node => [node.id, 0]));
  edges.forEach((edge, i) => {
    const from = clean(edge?.from, `edges[${i}].from`);
    const to = clean(edge?.to, `edges[${i}].to`);
    if (!byId.has(from) || !byId.has(to)) throw new Error(`edge ${i} refers to an unknown node`);
    outgoing.get(from).push({ to, label: edge.label ? clean(edge.label, `edges[${i}].label`) : '' });
    incoming.set(to, incoming.get(to) + 1);
  });
  const start = input.start ? clean(input.start, 'start') : nodes.find(node => incoming.get(node.id) === 0)?.id ?? nodes[0].id;
  if (!byId.has(start)) throw new Error('start refers to an unknown node');
  const visited = new Set();
  const lines = [];
  function visit(id, prefix = '', connector = '') {
    const node = byId.get(id);
    const repeated = visited.has(id);
    lines.push(`${prefix}${connector}[${node.label}]${repeated ? ' ↩' : ''}`);
    if (repeated) return;
    visited.add(id);
    const next = outgoing.get(id);
    const continuation = prefix + (connector ? (connector.startsWith('└') ? '    ' : '│   ') : '');
    next.forEach((edge, i) => {
      const branch = i === next.length - 1 ? '└── ' : '├── ';
      visit(edge.to, continuation, `${branch}${edge.label ? `${edge.label} → ` : ''}`);
    });
  }
  visit(start);
  const remaining = nodes.filter(node => !visited.has(node.id));
  if (remaining.length) {
    lines.push('', 'Other components:');
    remaining.forEach(node => { if (!visited.has(node.id)) visit(node.id); });
  }
  return lines.join('\n');
}

export function renderSequence(input) {
  const participants = limit(input.participants, 'participants', 8).map((p, i) => clean(p, `participants[${i}]`));
  if (new Set(participants).size !== participants.length) throw new Error('participants must be unique');
  const messages = limit(input.messages, 'messages', 40).map((message, i) => {
    const from = clean(message?.from, `messages[${i}].from`);
    const to = clean(message?.to, `messages[${i}].to`);
    const label = clean(message?.label, `messages[${i}].label`);
    if (!participants.includes(from) || !participants.includes(to)) throw new Error(`message ${i} refers to an unknown participant`);
    return { from, to, label };
  });
  const width = Math.max(14, ...participants.map(p => p.length + 4));
  const centers = participants.map((_, i) => Math.floor(width / 2) + i * width);
  const size = width * participants.length;
  function blank() { return Array(size).fill(' '); }
  function row(chars) { return chars.join('').trimEnd(); }
  const header = blank();
  participants.forEach((p, i) => { const left = centers[i] - Math.floor(p.length / 2); [...p].forEach((char, j) => { header[left + j] = char; }); });
  const lines = [row(header)];
  messages.forEach(({ from, to, label }) => {
    const a = centers[participants.indexOf(from)];
    const b = centers[participants.indexOf(to)];
    const stem = blank(); centers.forEach(c => { stem[c] = '│'; });
    if (a === b) {
      lines.push(row(stem));
      lines.push(`${' '.repeat(a)}└─ ${label} ↺`);
      return;
    }
    const left = Math.min(a, b), right = Math.max(a, b);
    const arrow = blank(); centers.forEach(c => { arrow[c] = '│'; });
    for (let i = left + 1; i < right; i++) arrow[i] = '─';
    arrow[a] = a < b ? '├' : '┤';
    arrow[b] = a < b ? '▶' : '◀';
    lines.push(row(stem));
    lines.push(row(arrow));
    lines.push(`${' '.repeat(left + 1)}${label}`);
  });
  const footer = blank(); centers.forEach(c => { footer[c] = '│'; });
  lines.push(row(footer));
  return lines.join('\n');
}

export function renderDiagram(input) {
  if (!input || typeof input !== 'object') throw new Error('input must be an object');
  if (input.kind === 'flowchart') return renderFlowchart(input);
  if (input.kind === 'sequence') return renderSequence(input);
  throw new Error('kind must be flowchart or sequence');
}

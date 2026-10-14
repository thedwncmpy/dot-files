# Codex diagrams

A local Codex MCP server for diagrams in chat. `render_mermaid` accepts any diagram syntax supported by the installed Mermaid CLI version, renders a PNG and SVG, and returns a text preview that Codex CLI can show in the terminal. Mermaid sequence diagrams get a readable Unicode layout; other Mermaid types get a compact character preview. The tool also returns the PNG as MCP image content and saves the source and image files under `generated/`. `render_diagram` provides terminal-friendly Unicode flowcharts and sequence diagrams from structured input.

## Requirements

- Node.js 20 or newer
- Google Chrome at `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
- `npm install --ignore-scripts` in this directory

The Chrome path is set in `puppeteer-config.json`. Change it if your browser is elsewhere.

## Connect to Codex CLI

From this directory:

```sh
codex mcp add diagrams -- node "$PWD/server.mjs"
```

To allow the local tools in noninteractive Codex runs, add these settings to `~/.codex/config.toml`:

```toml
[mcp_servers.diagrams.tools.render_mermaid]
approval_mode = "approve"

[mcp_servers.diagrams.tools.render_diagram]
approval_mode = "approve"
```

Restart Codex after configuring the server. Try:

> Draw a Mermaid sequence diagram for a browser request through an API and database. Use `diagrams.render_mermaid`, show its terminal preview in a plain text code block, and link the PNG.

Or, for a diagram made entirely of text in the terminal:

> Draw a small flowchart of request validation. Use `diagrams.render_diagram` and paste its output in a text code block.

The MCP image is available to Codex in its chat context. Codex CLI may replace image links with a label and may not render some Mermaid code fences, so the terminal preview is the visible result in CLI chat. Open the PNG or SVG for full detail. Character previews of large or complex diagrams can lose labels; shorten the source or use the saved image in that case.

`codex mcp get diagrams` checks the connection. `codex mcp remove diagrams` removes it.

# Notion Zsh Integration

This module provides a seamless way to sync local Markdown notes to a master Notion database with relational categorization.

## 📂 Directory Structure

- `notion.zsh`: The primary entry point containing Zsh functions and API logic.
- `notion_parser.py`: Python helper that translates Markdown (Rich Text, Headers, Callouts, Checklists) into Notion Blocks.
- `secrets.zsh`: (**GIT IGNORED**) Stores sensitive API tokens and Database IDs.

## 🚀 Functions

### `notion-upload <file>`
The primary command for syncing a Markdown file.
- **Title**: Uses the filename (e.g., `ideas.md` -> "ideas").
- **Notebook Mapping**: Automatically detects the notebook based on the file's parent directory within `~/notes/`.
- **Rich Text**: Supports **Bold**, *Italics*, Headers (H1-H3), Bulleted Lists, Checklists, and Callouts.
- **Duplicate Check**: Verifies if a page with the same name exists in the master database before uploading.

### `notion-note <notebook> <text>`
A quick-entry command for short snippets.
- Sends a simple text-only note to the specified notebook without requiring a local file.

## ⚙️ Setup & Environment Variables

The following variables must be defined in `notion/secrets.zsh`:

| Variable | Description |
|----------|-------------|
| `NOTION_TOKEN` | Your Notion Internal Integration Token. |
| `NOTION_NOTES_DB_ID` | The ID of your master "Notes" Database. |

### Relational Mapping
The script uses a helper function `_get_notion_id` inside `notion.zsh` to map folder names (e.g., `scratch`, `blogs`) to their respective **Page IDs** in your Notion Notebooks database.

## 🛠 Execution Flow

1. **Invocation**: You run `notion-upload path/to/note.md`.
2. **Path Resolution**: Zsh resolves the absolute path and identifies the "Notebook" name from the folder structure.
3. **Parsing**: The Zsh function calls `notion_parser.py`.
4. **Translation**: Python parses the Markdown line-by-line:
   - Identifies block types (Paragraph, Header, To-Do, etc.).
   - Breaks down lines into "Rich Text" objects for styling (Bold/Italics).
   - Returns a JSON array of Notion blocks.
5. **API Request**: Zsh uses `curl` to send a POST request to the Notion API, creating a new page in the master database with a relation link to the correct notebook.

---

**Note**: Ensure `notion/secrets.zsh` is added to your `.gitignore` to prevent leaking credentials!

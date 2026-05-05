# Notion Integration Logic

# Load secrets from the same directory
if [[ -f "$HOME/.config/zshrc/notion/secrets.zsh" ]]; then
  source "$HOME/.config/zshrc/notion/secrets.zsh"
fi

_get_notion_id() {
  case "$1" in
    "scratch")  echo "32f73c7809a980b5a915f2ed8b4569f1" ;;
    "blogs")    echo "31873c7809a9805a9600e0a68b526073" ;;
    "leetcode") echo "31073c7809a9800cb72eead179920e33" ;;
    "project")  echo "31073c7809a9814cbb12eaae5f716728" ;;
    "sil")      echo "31673c7809a980f28fd7db2e5c1972dd" ;;
    *) return 1 ;;
  esac
}

notion-note() {
  local NOTEBOOK_NAME="$1"
  shift 
  local NOTE_TEXT="$*"
  local NOTEBOOK_ID=$(_get_notion_id "$NOTEBOOK_NAME")

  if [[ -z "$NOTEBOOK_ID" ]]; then
    echo "Error: Notebook '$NOTEBOOK_NAME' not found."
    return 1
  fi

  echo "Sending note to $NOTEBOOK_NAME..."
  
  local payload=$(jq -n \
    --arg db "$NOTION_NOTES_DB_ID" \
    --arg notebook_id "$NOTEBOOK_ID" \
    --arg text "$NOTE_TEXT" \
    '{
      parent: { database_id: $db },
      properties: {
        Name: { title: [{ text: { content: $text } }] },
        notebook: { relation: [{ id: $notebook_id }] }
      }
    }')

  local response=$(curl -s -X POST "https://api.notion.com/v1/pages" \
    -H "Authorization: Bearer $NOTION_TOKEN" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    --data "$payload")

  if echo "$response" | jq -e '.object == "error"' > /dev/null; then
    echo "  [Error] Notion API: $(echo "$response" | jq -r '.message')"
    return 1
  fi

  echo "Done!"
}

notion-upload() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' not found."
    return 1
  fi

  local NOTES_DIR="$HOME/notes"
  local abs_path="${file:A}"
  
  if [[ "$abs_path" != "$NOTES_DIR"* ]]; then
    echo "Error: File must be inside $NOTES_DIR"
    return 1
  fi

  local relative_to_notes="${abs_path#$NOTES_DIR/}"
  local notebook="${relative_to_notes%%/*}"
  local notebook_id=$(_get_notion_id "$notebook")

  if [[ -z "$notebook_id" ]]; then
    echo "Error: Could not map directory '$notebook' to a Notion Notebook ID."
    return 1
  fi

  local title=$(basename "$file" .md)

  echo "  [Syncing] '$title' to $notebook..."

  # Search for existing page
  local filter=$(jq -n --arg title "$title" '{filter: {property: "Name", title: {equals: $title}}}')
  local search_response=$(curl -s -X POST "https://api.notion.com/v1/databases/$NOTION_NOTES_DB_ID/query" \
    -H "Authorization: Bearer $NOTION_TOKEN" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    --data "$filter")

  local page_id=$(echo "$search_response" | jq -r '.results[0].id // empty')
  
  local python_script="$HOME/.config/zshrc/notion/notion_parser.py"
  local blocks=$(python3 "$python_script" "$abs_path")

  if [[ $? -ne 0 ]]; then
    echo "  [Error] Failed to parse Markdown file."
    return 1
  fi

  if [[ -n "$page_id" ]]; then
    echo "  [Updating] Existing page '$title'..."
    
    # 1. Get existing blocks to delete
    local existing_blocks=$(curl -s -X GET "https://api.notion.com/v1/blocks/$page_id/children" \
      -H "Authorization: Bearer $NOTION_TOKEN" \
      -H "Notion-Version: 2022-06-28" | jq -r '.results[].id')

    # 2. Delete each block
    for block_id in ${(f)existing_blocks}; do
      curl -s -X DELETE "https://api.notion.com/v1/blocks/$block_id" \
        -H "Authorization: Bearer $NOTION_TOKEN" \
        -H "Notion-Version: 2022-06-28" > /dev/null
    done

    # 3. Append new blocks
    local payload=$(jq -n --argjson blocks "$blocks" '{children: $blocks}')
    local response=$(curl -s -X PATCH "https://api.notion.com/v1/blocks/$page_id/children" \
      -H "Authorization: Bearer $NOTION_TOKEN" \
      -H "Notion-Version: 2022-06-28" \
      -H "Content-Type: application/json" \
      --data "$payload")
  else
    echo "  [Creating] New page '$title'..."
    local payload=$(jq -n \
      --arg db "$NOTION_NOTES_DB_ID" \
      --arg notebook_id "$notebook_id" \
      --arg title "$title" \
      --argjson blocks "$blocks" \
      '{
        parent: { database_id: $db },
        properties: {
          Name: { title: [{ text: { content: $title } }] },
          notebook: { relation: [{ id: $notebook_id }] }
        },
        children: $blocks
      }')

    local response=$(curl -s -X POST "https://api.notion.com/v1/pages" \
      -H "Authorization: Bearer $NOTION_TOKEN" \
      -H "Notion-Version: 2022-06-28" \
      -H "Content-Type: application/json" \
      --data "$payload")
  fi

  if echo "$response" | jq -e '.object == "error"' > /dev/null; then
    echo "  [Error] Notion API: $(echo "$response" | jq -r '.message')"
    return 1
  fi
  
  echo "  Done!"
}

notion-download() {
  local file="$1"
  if [[ -z "$file" ]]; then
    echo "Usage: notion-download <file>"
    return 1
  fi

  local NOTES_DIR="$HOME/notes"
  local abs_path="${file:A}"
  
  if [[ "$abs_path" != "$NOTES_DIR"* ]]; then
    echo "Error: File must be inside $NOTES_DIR"
    return 1
  fi

  local title=$(basename "$file" .md)

  echo "  [Fetching] '$title' from Notion..."

  # Search for the page ID by title
  local filter=$(jq -n --arg title "$title" '{filter: {property: "Name", title: {equals: $title}}}')
  local response=$(curl -s -X POST "https://api.notion.com/v1/databases/$NOTION_NOTES_DB_ID/query" \
    -H "Authorization: Bearer $NOTION_TOKEN" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    --data "$filter")

  local page_id=$(echo "$response" | jq -r '.results[0].id // empty')

  if [[ -z "$page_id" ]]; then
    echo "  [Error] Page '$title' not found in Notion."
    return 1
  fi

  # Fetch block children
  local blocks_response=$(curl -s -X GET "https://api.notion.com/v1/blocks/$page_id/children" \
    -H "Authorization: Bearer $NOTION_TOKEN" \
    -H "Notion-Version: 2022-06-28")

  if echo "$blocks_response" | jq -e '.object == "error"' > /dev/null; then
    echo "  [Error] Notion API: $(echo "$blocks_response" | jq -r '.message')"
    return 1
  fi

  local python_script="$HOME/.config/zshrc/notion/notion_parser.py"
  local md_content=$(echo "$blocks_response" | jq '.results' | python3 "$python_script" --reverse)

  if [[ $? -ne 0 ]]; then
    echo "  [Error] Failed to convert Notion blocks to Markdown."
    return 1
  fi

  echo "$md_content" > "$abs_path"
  echo "  Done! Overwritten $file"
}

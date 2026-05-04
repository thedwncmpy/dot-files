import sys
import json
import re

def parse_inline_text(text):
    """
    Parses bold and italics in a string and returns Notion rich_text objects.
    """
    # Regex for bold (**text** or __text__) and italics (*text* or _text_)
    # This is a simplified parser; it handles basic nesting but not perfectly.
    
    parts = []
    # Pattern to match bold, italics, or plain text
    # Order matters: Bold first, then Italics
    pattern = r'(\*\*\*.*?\*\*\*|\*\*.*?\*\*|__.*?__|(\*|_).*?(\*|_)|.+?)'
    
    # We use a more iterative approach for simple inline parsing
    remaining = text
    while remaining:
        # Bold + Italic (***text***)
        bi_match = re.match(r'^(\*\*\*|___)(.*?)\1(.*)', remaining)
        if bi_match:
            parts.append({
                "text": {"content": bi_match.group(2)},
                "annotations": {"bold": True, "italic": True}
            })
            remaining = bi_match.group(3)
            continue

        # Bold (**text**)
        bold_match = re.match(r'^(\*\*|__)(.*?)\1(.*)', remaining)
        if bold_match:
            parts.append({
                "text": {"content": bold_match.group(2)},
                "annotations": {"bold": True}
            })
            remaining = bold_match.group(3)
            continue

        # Italic (*text*)
        italic_match = re.match(r'^(\*|_)(.*?)\1(.*)', remaining)
        if italic_match:
            parts.append({
                "text": {"content": italic_match.group(2)},
                "annotations": {"italic": True}
            })
            remaining = italic_match.group(3)
            continue
            
        # Plain text (up to the next potential symbol)
        plain_match = re.match(r'^([^*_]+)(.*)', remaining)
        if plain_match:
            parts.append({"text": {"content": plain_match.group(1)}})
            remaining = plain_match.group(2)
        else:
            # Fallback for single characters that aren't matches
            parts.append({"text": {"content": remaining[0]}})
            remaining = remaining[1:]

    return parts

def md_to_notion_blocks(md_text):
    blocks = []
    lines = md_text.splitlines()
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Headers
        if line.startswith("# "):
            blocks.append({
                "object": "block",
                "type": "heading_1",
                "heading_1": {"rich_text": parse_inline_text(line[2:])}
            })
        elif line.startswith("## "):
            blocks.append({
                "object": "block",
                "type": "heading_2",
                "heading_2": {"rich_text": parse_inline_text(line[3:])}
            })
        elif line.startswith("### "):
            blocks.append({
                "object": "block",
                "type": "heading_3",
                "heading_3": {"rich_text": parse_inline_text(line[4:])}
            })
            
        # Checklists
        elif line.startswith("- [ ] "):
            blocks.append({
                "object": "block",
                "type": "to_do",
                "to_do": {"rich_text": parse_inline_text(line[6:]), "checked": False}
            })
        elif line.startswith("- [x] ") or line.startswith("- [X] "):
            blocks.append({
                "object": "block",
                "type": "to_do",
                "to_do": {"rich_text": parse_inline_text(line[6:]), "checked": True}
            })
            
        # Bulleted Lists
        elif line.startswith("- ") or line.startswith("* "):
            blocks.append({
                "object": "block",
                "type": "bulleted_list_item",
                "bulleted_list_item": {"rich_text": parse_inline_text(line[2:])}
            })
            
        # Callouts (using > syntax)
        elif line.startswith("> "):
            content = line[2:]
            icon = "💡" # Default icon
            # Check for [!INFO], [!WARNING], etc.
            alert_match = re.match(r'^\[!(.*?)\]\s*(.*)', content)
            if alert_match:
                alert_type = alert_match.group(1).upper()
                content = alert_match.group(2)
                if "WARN" in alert_type: icon = "⚠️"
                elif "ERROR" in alert_type or "DANGER" in alert_type: icon = "🚨"
                elif "INFO" in alert_type: icon = "ℹ️"
                elif "SUCCESS" in alert_type: icon = "✅"
            
            blocks.append({
                "object": "block",
                "type": "callout",
                "callout": {
                    "rich_text": parse_inline_text(content),
                    "icon": {"emoji": icon}
                }
            })
            
        # Paragraph (Default)
        else:
            blocks.append({
                "object": "block",
                "type": "paragraph",
                "paragraph": {"rich_text": parse_inline_text(line)}
            })
            
    return blocks[:100] # Notion API limit per request

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
        
    file_path = sys.argv[1]
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        print(json.dumps(md_to_notion_blocks(content)))
    except Exception as e:
        sys.stderr.write(f"Error: {str(e)}\n")
        sys.exit(1)

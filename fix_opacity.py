import re
import os

base = r"C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\frontend\lib"

files = [
    r"screens\market\market_screen.dart",
    r"screens\market\market_screen_simple.dart",
    r"screens\portfolio\portfolio_screen.dart",
    r"screens\settings\settings_screen.dart",
    r"screens\stock_detail\stock_detail_screen.dart",
    r"screens\tools\tools_screen.dart",
    r"screens\watchlist\watchlist_screen.dart",
    r"widgets\index_card.dart",
    r"widgets\stock_row.dart",
]

def fix_with_opacity(text):
    """Convert .withOpacity(x) to .withValues(alpha: x)"""
    return re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', text)

for rel_path in files:
    full_path = os.path.join(base, rel_path)
    if not os.path.exists(full_path):
        print(f"SKIP (not found): {rel_path}")
        continue
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = fix_with_opacity(content)
    
    if new_content != content:
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        count = content.count('.withOpacity(')
        print(f"Fixed {count} withOpacity calls: {rel_path}")
    else:
        print(f"No changes: {rel_path}")

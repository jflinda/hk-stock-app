import re

files_to_fix = [
    r"C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\frontend\lib\services\api_service.dart",
]

for path in files_to_fix:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace print( with debugPrint( 
    new_content = content.replace("logPrint: (obj) => print('[Dio] $obj')", "logPrint: (obj) => debugPrint('[Dio] $obj')")
    new_content = re.sub(r'\bprint\(', 'debugPrint(', new_content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Fixed: {path}")

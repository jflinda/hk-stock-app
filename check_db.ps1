$env:PYTHONIOENCODING = 'utf-8'
$python = 'C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe'
$script = 'C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\check_db.py'
$outFile = 'C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\check_db_output.txt'
$output = & $python $script 2>&1
$output | Out-File -FilePath $outFile -Encoding utf8
Get-Content $outFile

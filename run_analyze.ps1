$env:PYTHONIOENCODING = 'utf-8'
Set-Location 'C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\frontend'
$out = & 'C:\flutter\flutter\bin\flutter.bat' analyze 2>&1
$out | Out-File -FilePath 'C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\analyze_output.txt' -Encoding utf8
Write-Output "EXIT: $LASTEXITCODE"
Write-Output "--- Last 30 lines ---"
$out | Select-Object -Last 30

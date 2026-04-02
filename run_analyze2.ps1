$flutterPath = "C:\flutter\flutter\bin\flutter.bat"
$frontendDir = "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\frontend"
Set-Location $frontendDir
$result = & $flutterPath analyze 2>&1
$result | Out-File -FilePath "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\analyze_result.txt" -Encoding UTF8
Write-Host "Flutter analyze done. Exit: $LASTEXITCODE"
$result | Select-Object -Last 30

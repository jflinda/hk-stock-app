$flutterPath = "C:\flutter\flutter\bin\flutter.bat"
$frontendDir = "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\frontend"
Set-Location $frontendDir

Write-Host "=== flutter pub get ==="
$pubGet = & $flutterPath pub get 2>&1
$pubGet | Out-File -FilePath "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\pub_get_result.txt" -Encoding UTF8
$pubGet | Select-Object -Last 5
Write-Host "pub get exit: $LASTEXITCODE"

Write-Host ""
Write-Host "=== flutter analyze ==="
$analyze = & $flutterPath analyze 2>&1
$analyze | Out-File -FilePath "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\analyze_result2.txt" -Encoding UTF8
$analyze | Select-Object -Last 15
Write-Host "analyze exit: $LASTEXITCODE"

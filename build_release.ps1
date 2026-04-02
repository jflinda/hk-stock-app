$flutterPath = "C:\flutter\flutter\bin\flutter.bat"
$frontendDir = "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\frontend"
Set-Location $frontendDir

Write-Host "=== Building release APK ==="
Write-Host "Started at: $(Get-Date -Format 'HH:mm:ss')"
$result = & $flutterPath build apk --release 2>&1
$result | Out-File -FilePath "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\build_release_result.txt" -Encoding UTF8
Write-Host "Finished at: $(Get-Date -Format 'HH:mm:ss')"
Write-Host "Exit code: $LASTEXITCODE"
$result | Select-Object -Last 20

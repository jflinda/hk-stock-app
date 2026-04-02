$pythonPath = "C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe"
$backendDir = "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend"
Set-Location $backendDir
Start-Process -FilePath $pythonPath -ArgumentList "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001", "--reload" -WindowStyle Hidden
Write-Host "API server starting on port 8001..."
Start-Sleep -Seconds 4
Write-Host "Done. Testing ping..."
try {
    $r = Invoke-WebRequest -Uri "http://localhost:8001/ping" -TimeoutSec 5
    Write-Host "API OK: $($r.Content)"
} catch {
    Write-Host "API not yet ready: $_"
}

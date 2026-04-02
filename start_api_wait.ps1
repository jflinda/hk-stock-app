$pythonPath = "C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe"
$backendDir = "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend"
Set-Location $backendDir
Start-Process -FilePath $pythonPath -ArgumentList "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001" -WindowStyle Hidden
Write-Host "Waiting for server to start..."
$ready = $false
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 2
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8001/ping" -TimeoutSec 3 -ErrorAction Stop
        Write-Host "API is UP: $($r.Content)"
        $ready = $true
        break
    } catch {
        Write-Host "Attempt $($i+1): not ready yet..."
    }
}
if (-not $ready) { Write-Host "Server did not start in time." }

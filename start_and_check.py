import subprocess
import sys
import time
import urllib.request

python_path = r"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe"
backend_dir = r"C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend"

# Start uvicorn in background
proc = subprocess.Popen(
    [python_path, "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"],
    cwd=backend_dir,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE
)
print(f"Started uvicorn PID: {proc.pid}")

# Wait for it to be ready
for i in range(15):
    time.sleep(2)
    try:
        resp = urllib.request.urlopen("http://localhost:8001/ping", timeout=3)
        print(f"API UP: {resp.read().decode()}")
        break
    except Exception as e:
        print(f"Attempt {i+1}: {e}")
else:
    print("Server did not start. Checking stderr:")
    try:
        out, err = proc.communicate(timeout=2)
        print("STDOUT:", out.decode()[:500])
        print("STDERR:", err.decode()[:500])
    except:
        pass

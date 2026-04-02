import subprocess
import sys

python_path = r"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe"
backend_dir = r"C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend"

proc = subprocess.Popen(
    [python_path, "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"],
    cwd=backend_dir,
    stdout=open(r"C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\api_stdout.log", "w"),
    stderr=open(r"C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\api_stderr.log", "w"),
    creationflags=subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
)
print(f"Launched uvicorn PID: {proc.pid}")

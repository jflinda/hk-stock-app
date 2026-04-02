@echo off
echo 启动API服务器监控系统...
echo 监控日志将保存在: monitor_logs\ 目录
echo 按Ctrl+C停止监控

cd /d "%~dp0"

REM 创建监控日志目录
if not exist monitor_logs mkdir monitor_logs

REM 启动监控脚本
"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" monitor_api.py

pause
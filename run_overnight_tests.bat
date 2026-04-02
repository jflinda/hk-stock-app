@echo off
echo 港股投资应用过夜自动化测试系统
echo ==========================================
echo 开始时间: %date% %time%
echo.

REM 创建测试日志目录
if not exist test_logs mkdir test_logs
if not exist monitor_logs mkdir monitor_logs
if not exist e2e_logs mkdir e2e_logs

echo 1. 启动API服务器监控...
start "API Monitor" cmd /c "C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" monitor_api.py
timeout /t 5 /nobreak >nul

echo 2. 运行Flutter应用功能测试...
echo 开始Flutter应用测试: %date% %time% >> test_logs\test_start.log
start "Flutter Test" cmd /c "C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" test_flutter_app.py
timeout /t 10 /nobreak >nul

echo 3. 运行端到端集成测试...
echo 开始端到端测试: %date% %time% >> test_logs\test_start.log
start "E2E Test" cmd /c "C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" test_end_to_end.py

echo.
echo ==========================================
echo 所有测试已启动！
echo.
echo 监控窗口已打开，请勿关闭。
echo 测试结果将保存到以下目录：
echo   - monitor_logs\     API监控日志
echo   - test_logs\       Flutter测试日志
echo   - e2e_logs\        端到端测试日志
echo.
echo 按任意键查看测试状态...
pause >nul

echo.
echo ==========================================
echo 当前测试状态：
echo.

REM 检查进程状态
tasklist | findstr /i "python" >nul
if %errorlevel% equ 0 (
    echo ✓ Python测试进程正在运行
) else (
    echo ✗ Python测试进程未运行
)

REM 检查API服务器状态
curl -s http://localhost:8001/ping >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ API服务器正在运行
) else (
    echo ✗ API服务器未运行
)

echo.
echo ==========================================
echo 测试将持续运行直到明早8点
echo 按Ctrl+C可以提前停止所有测试
echo.
echo 当前时间: %date% %time%
echo.

REM 保持脚本运行，显示状态
:loop
echo 测试运行中... 按Ctrl+C停止
timeout /t 60 /nobreak >nul

REM 检查进程是否还在运行
tasklist | findstr /i "python" >nul
if %errorlevel% neq 0 (
    echo ✗ 测试进程已停止
    goto end
)

goto loop

:end
echo.
echo ==========================================
echo 测试已停止
echo 结束时间: %date% %time%
echo.
echo 测试结果总结：
echo.

REM 检查是否有测试报告
if exist test_logs\*.html (
    echo ✓ Flutter测试报告已生成
) else (
    echo ✗ 未找到Flutter测试报告
)

if exist e2e_logs\*.html (
    echo ✓ 端到端测试报告已生成
) else (
    echo ✗ 未找到端到端测试报告
)

if exist monitor_logs\*.json (
    echo ✓ API监控日志已生成
) else (
    echo ✗ 未找到API监控日志
)

echo.
echo 按任意键退出...
pause >nul
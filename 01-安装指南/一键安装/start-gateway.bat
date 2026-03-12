@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  OpenClaw Gateway - 检测 & 启动
::  检测端口 18789 是否监听，未启动则自动启动并验证
:: ============================================================

set "GATEWAY_PORT=18789"
set "MAX_WAIT=30"
set "POLL_INTERVAL=2"

echo.
echo ============================================================
echo   OpenClaw Gateway - Check ^& Start
echo ============================================================
echo.

:: ---- 检查 openclaw 命令是否可用 ----
where openclaw >nul 2>&1
if errorlevel 1 (
    echo [ERROR] openclaw command not found
    echo         Please run install-windows.bat first to install OpenClaw
    echo         Or restart the terminal and try again after PATH is updated
    echo.
    pause
    exit /b 1
)

:: ---- 检测 Gateway 是否已在运行（端口监听检测）----
echo [ INFO ] Checking Gateway status ^(port %GATEWAY_PORT%^)...
netstat -ano 2>nul | findstr ":%GATEWAY_PORT% " | findstr "LISTENING" >nul 2>&1
if not errorlevel 1 (
    echo [  OK  ] Gateway is already running, no need to start again
    echo.
    echo          Port %GATEWAY_PORT% is listening
    echo.
    openclaw gateway status 2>nul
    echo.
    pause
    exit /b 0
)

:: ---- Gateway 未运行，执行启动 ----
echo [ WARN ] Gateway is not running, starting...
echo.
openclaw gateway start
echo.

:: ---- 轮询等待进程就绪（最多 MAX_WAIT 秒）----
echo [ INFO ] Waiting for Gateway to become ready ^(up to %MAX_WAIT% seconds^)...
set "ELAPSED=0"

:PollLoop
if !ELAPSED! GEQ %MAX_WAIT% goto :PollTimeout

netstat -ano 2>nul | findstr ":%GATEWAY_PORT% " | findstr "LISTENING" >nul 2>&1
if not errorlevel 1 goto :PollSuccess

:: 显示等待进度
set /a "REMAINING=%MAX_WAIT% - !ELAPSED!"
<nul set /p "=[ INFO ] Waiting... elapsed !ELAPSED!s / %MAX_WAIT%s"
echo.
timeout /t %POLL_INTERVAL% /nobreak >nul
set /a "ELAPSED+=!POLL_INTERVAL!"
goto :PollLoop

:PollSuccess
echo.
echo [  OK  ] Gateway started successfully! Port %GATEWAY_PORT% is listening ^(elapsed !ELAPSED!s^)
echo.
openclaw gateway status 2>nul
echo.
pause
endlocal
exit /b 0

:PollTimeout
echo.
echo [ERROR] Gateway startup timed out. Port %GATEWAY_PORT% did not start listening within %MAX_WAIT% seconds
echo.
echo         Troubleshooting suggestions:
echo           1. View logs: openclaw gateway logs
echo           2. Start manually: openclaw gateway start
echo           3. Check status: openclaw gateway status
echo.
pause
endlocal
exit /b 1

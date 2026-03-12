@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  OpenClaw Gateway - 检测 & 启动
::  检测端口 18789 是否监听，未启动则自动启动并验证
:: ============================================================

set "GATEWAY_PORT=18789"
set "WAIT_SECONDS=5"

echo.
echo ============================================================
echo   OpenClaw Gateway - 检测 ^& 启动
echo ============================================================
echo.

:: ---- 检查 openclaw 命令是否可用 ----
where openclaw >nul 2>&1
if errorlevel 1 (
    echo [ERROR] openclaw 命令未找到
    echo         请先运行 install-windows.bat 安装 OpenClaw
    echo         或重启终端使 PATH 生效后重试
    echo.
    pause
    exit /b 1
)

:: ---- 检测 Gateway 是否已在运行（端口监听检测）----
echo [ INFO ] 正在检测 Gateway 状态（端口 %GATEWAY_PORT%）...
netstat -ano 2>nul | findstr ":%GATEWAY_PORT% " | findstr "LISTENING" >nul 2>&1
if not errorlevel 1 (
    echo [  OK  ] Gateway 已在运行中，无需重复启动
    echo.
    echo          端口 %GATEWAY_PORT% 正在监听
    echo.
    openclaw gateway status 2>nul
    echo.
    pause
    exit /b 0
)

:: ---- Gateway 未运行，执行启动 ----
echo [ WARN ] Gateway 未运行，正在启动...
echo.
openclaw gateway start
echo.

:: ---- 等待进程就绪 ----
echo [ INFO ] 等待 Gateway 就绪（%WAIT_SECONDS% 秒）...
timeout /t %WAIT_SECONDS% /nobreak >nul

:: ---- 验证启动结果 ----
echo [ INFO ] 正在验证启动结果...
netstat -ano 2>nul | findstr ":%GATEWAY_PORT% " | findstr "LISTENING" >nul 2>&1
if not errorlevel 1 (
    echo [  OK  ] Gateway 启动成功！端口 %GATEWAY_PORT% 已在监听
    echo.
    openclaw gateway status 2>nul
) else (
    echo [ERROR] Gateway 启动失败，端口 %GATEWAY_PORT% 未监听
    echo.
    echo         排查建议：
    echo           1. 查看日志: openclaw gateway logs
    echo           2. 手动启动: openclaw gateway start
    echo           3. 查看状态: openclaw gateway status
    echo.
    exit /b 1
)

echo.
pause
endlocal
exit /b 0

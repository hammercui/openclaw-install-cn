@echo off
REM ============================================
REM OpenClaw 一键安装脚本 (Windows 入口)
REM ============================================

echo.
echo ============================================
echo    OpenClaw 一键安装
echo ============================================
echo.

REM 检查 PowerShell 是否可用
where powershell >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到 PowerShell，请安装 PowerShell 5.0 或更高版本
    echo 下载地址: https://aka.ms/powershell
    pause
    exit /b 1
)

REM 使用 PowerShell 运行安装脚本
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0install.ps1"

REM 检查安装结果
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo [成功] OpenClaw 安装完成！
    echo ============================================
    echo.
    echo 下一步操作:
    echo   1. openclaw init           (初始化配置)
    echo   2. openclaw gateway start  (启动 Gateway)
    echo   3. openclaw gateway status (查看状态)
    echo.
    echo 详细文档: ..\README.md
    echo.
) else (
    echo.
    echo ============================================
    echo [失败] 安装失败，请查看错误信息
    echo ============================================
    echo.
)

pause

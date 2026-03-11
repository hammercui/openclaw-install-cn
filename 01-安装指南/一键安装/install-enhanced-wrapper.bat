@echo off
REM ============================================
REM OpenClaw 增强版一键安装脚本 (Windows 入口)
REM ============================================

echo.
echo ============================================
echo    OpenClaw 增强版一键安装
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

REM 使用 PowerShell 运行增强版安装脚本
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0install-enhanced.ps1"

REM 检查安装结果
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo [成功] OpenClaw 安装完成！
    echo ============================================
    echo.
    echo 增强版特性:
    echo   - 自动测试并选择最快的镜像源
    echo   - 永久配置（重启终端不丢失）
    echo   - 支持开机启动配置
    echo.
) else (
    echo.
    echo ============================================
    echo [失败] 安装失败，请查看错误信息
    echo ============================================
    echo.
)

pause

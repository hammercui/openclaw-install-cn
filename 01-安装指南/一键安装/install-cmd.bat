@echo off
REM ============================================
REM OpenClaw 一键安装脚本 (Windows 纯批处理版本)
REM ============================================
REM
REM 功能：完全使用批处理命令安装 OpenClaw
REM 适用于：Windows 7/8/10/11
REM 需要：网络连接、管理员权限（可选）
REM
REM ============================================

setlocal enabledelayedexpansion

REM 设置代码页为 UTF-8
chcp 65001 >nul 2>nul

echo.
echo ============================================
echo    OpenClaw 一键安装 (纯批处理版)
echo ============================================
echo.

REM ============================================
REM 1. 检查 Node.js 是否已安装
REM ============================================
echo [1/6] 检查 Node.js...
where node >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%i in ('node -v') do set NODE_VERSION=%%i
    echo [OK] Node.js 已安装: !NODE_VERSION!
    echo.
    goto :check_npm
)

echo [信息] Node.js 未安装，开始安装...

REM 检查是否有 nvm
where nvm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [发现] nvm 已安装，使用 nvm 安装 Node.js
    nvm install 22
    nvm use 22
    if %ERRORLEVEL% NEQ 0 (
        echo [错误] Node.js 安装失败
        pause
        exit /b 1
    )
) else (
    echo [下载] 正在下载 Node.js 安装程序...
    
    REM 设置下载 URL（使用国内镜像）
    set "NODE_URL=https://npmmirror.com/mirrors/node/v22.11.0/node-v22.11.0-x64.msi"
    
    REM 下载到临时目录
    set "TEMP_FILE=%TEMP%\node-installer.msi"
    
    echo [提示] 正在使用 BITS 下载...
    bitsadmin /transfer node_download /priority /normal %NODE_URL% %TEMP_FILE%
    
    if %ERRORLEVEL% NEQ 0 (
        echo [备选] BITS 失败，尝试使用 PowerShell 下载...
        powershell -Command "& {Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%TEMP_FILE%'}"
        if %ERRORLEVEL% NEQ 0 (
            echo [错误] 下载失败，请手动下载 Node.js: %NODE_URL%
            pause
            exit /b 1
        )
    fi
    
    echo [安装] 正在安装 Node.js...
    msiexec /i %TEMP_FILE% /quiet /norestart
    if %ERRORLEVEL% NEQ 0 (
        echo [错误] Node.js 安装失败
        pause
        exit /b 1
    )
    
    echo [清理] 删除临时文件...
    del %TEMP_FILE% 2>nul
    
    echo [等待] 等待安装完成...
    timeout /t 5 /nobreak >nul
    
    REM 刷新环境变量
    refreshenv 2>nul
    echo [OK] Node.js 安装完成
    echo.
)

REM ============================================
REM 2. 配置 npm 镜像源
REM ============================================
:check_npm
echo [2/6] 配置 npm 镜像源...

REM 设置淘宝镜像
npm config set registry https://registry.npmmirror.com
if %ERRORLEVEL% EQU 0 (
    echo [OK] npm 镜像源配置成功（淘宝镜像）
) else (
    echo [警告] 镜像源配置失败，使用默认源
)

REM 配置 Node.js 镜像（用于 nvm）
set "NVM_NODE_MIRROR=https://npmmirror.com/mirrors/node"
if not exist "%APPDATA%\nvm" mkdir "%APPDATA%\nvm"
echo %NVM_NODE_MIRROR% > "%APPDATA%\nvm\settings.txt"

echo.

REM ============================================
REM 3. 安装 OpenClaw
REM ============================================
echo [3/6] 安装 OpenClaw...

REM 检查全局安装
npm list -g openclaw >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [信息] OpenClaw 已安装，尝试更新...
    npm update -g openclaw
) else (
    echo [安装] 正在安装 OpenClaw...
    npm install -g openclaw
)

if %ERRORLEVEL% NEQ 0 (
    echo [错误] OpenClaw 安装失败
    echo.
    echo 可能的原因：
    echo   1. 网络连接问题
    echo   2. npm 镜像源访问失败
    echo   3. 权限不足
    echo.
    echo 建议：
    echo   1. 检查网络连接
    echo   2. 尝试使用管理员权限运行
    echo   3. 手动设置镜像源: npm config set registry https://registry.npmmirror.com
    echo.
    pause
    exit /b 1
)

echo [OK] OpenClaw 安装完成
echo.

REM ============================================
REM 4. 验证安装
REM ============================================
echo [4/6] 验证安装...

REM 验证 openclaw 命令
where openclaw >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [警告] openclaw 命令未找到，尝试刷新环境变量...
    setx PATH "%PATH%;%APPDATA%\npm" >nul
    set "PATH=%PATH%;%APPDATA%\npm"
    
    where openclaw >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo [错误] openclaw 命令仍未找到
        echo.
        echo 请手动添加到 PATH: %%APPDATA%%\npm
        pause
        exit /b 1
    )
)

REM 获取版本号
for /f "tokens=*" %%i in ('openclaw --version') do set OPENCLAW_VERSION=%%i
echo [OK] OpenClaw 版本: !OPENCLAW_VERSION!
echo.

REM ============================================
REM 5. 检查依赖服务
REM ============================================
echo [5/6] 检查依赖服务...

REM 检查 Node.js 版本
for /f "tokens=1" %%i in ('node -v') do set NODE_VER=%%i
set NODE_VER=%NODE_VER:v=%
echo [信息] Node.js 版本: %NODE_VER%

REM 简单的版本检查
if %NODE_VER:~0,2% LSS 18 (
    echo [警告] Node.js 版本过低，建议使用 Node.js 18 或更高版本
    echo 当前版本: %NODE_VER%
    echo 推荐版本: 22.x
    echo.
)

REM 检查 npm 版本
for /f "tokens=*" %%i in ('npm -v') do set NPM_VERSION=%%i
echo [信息] npm 版本: %NPM_VERSION%
echo.

REM ============================================
REM 6. 完成安装
REM ============================================
echo [6/6] 安装总结
echo.
echo ============================================
echo [成功] OpenClaw 安装完成！
echo ============================================
echo.
echo 安装信息：
echo   - OpenClaw 版本: !OPENCLAW_VERSION!
echo   - Node.js 版本: %NODE_VER%
echo   - npm 版本: %NPM_VERSION%
echo   - npm 镜像: 淘宝镜像
echo.
echo 下一步操作：
echo   1. 初始化配置:
echo      openclaw init
echo.
echo   2. 启动 Gateway:
echo      openclaw gateway start
echo.
echo   3. 查看状态:
echo      openclaw gateway status
echo.
echo   4. 查看帮助:
echo      openclaw --help
echo.
echo 文档位置:
echo   - 快速开始: ..\QUICKSTART.md
echo   - 完整文档: ..\README.md
echo   - 故障排除: TROUBLESHOOTING.md
echo.
echo ============================================

REM 询问是否立即初始化
echo.
set /p INIT="是否立即初始化 OpenClaw? (Y/N): "
if /i "%INIT%"=="Y" (
    echo.
    echo [初始化] 正在初始化 OpenClaw...
    openclaw init
    if %ERRORLEVEL% EQU 0 (
        echo [OK] 初始化完成！
        echo.
        echo 现在可以运行: openclaw gateway start
    ) else (
        echo [警告] 初始化失败，可以稍后手动运行: openclaw init
    )
)

echo.
echo ============================================
echo 感谢使用 OpenClaw！
echo ============================================
echo.

pause
endlocal

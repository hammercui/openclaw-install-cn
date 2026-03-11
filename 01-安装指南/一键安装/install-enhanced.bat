@echo off
REM ============================================
REM OpenClaw 增强版一键安装脚本
REM ============================================
REM
REM 功能：
REM - 自动测试多个镜像源速度
REM - 选择最快的镜像源
REM - 永久配置（重启终端不丢失）
REM - 支持开机启动
REM
REM ============================================

setlocal enabledelayedexpansion

REM 设置代码页为 UTF-8
chcp 65001 >nul 2>nul

echo.
echo ============================================
echo    OpenClaw 增强版一键安装
echo ============================================
echo.

REM ============================================
REM 镜像源配置
REM ============================================

REM 定义 npm 镜像源列表
set "NPM_MIRRORS[0]=https://registry.npmmirror.com|淘宝镜像"
set "NPM_MIRRORS[1]=https://mirrors.cloud.tencent.com/npm/|腾讯云镜像"
set "NPM_MIRRORS[2]=https://registry.npmmirror.com|清华镜像（通过淘宝）"
set "NPM_MIRRORS[3]=https://mirrors.huaweicloud.com/repository/npm/|华为云镜像"

REM 定义 Node.js 下载镜像
set "NODE_MIRRORS[0]=https://npmmirror.com/mirrors/node/|淘宝镜像"
set "NODE_MIRRORS[1]=https://mirrors.cloud.tencent.com/nodejs-release/|腾讯云镜像"
set "NODE_MIRRORS[2]=https://mirrors.huaweicloud.com/nodejs/|华为云镜像"

REM ============================================
REM 速度测试函数
REM ============================================

:MirrorSpeedTest
set "MIRROR_URL=%~1"
set "MIRROR_NAME=%~2"

REM 使用 ping 测试延迟（兼容性最好）
for /f "tokens=4 delims==" %%i in ('ping -n 1 %~2 2^>nul ^| findstr /i "平均"') do (
    set "LATENCY=%%i"
    goto :MirrorTestResult
)

REM 如果没有平均延迟，尝试提取时间
for /f "tokens=2 delims==" %%i in ('ping -n 1 %~2 2^>nul ^| findstr /i /c:"time="') do (
    for /f "tokens=1,2 delims=m" %%a in ("%%i") do (
        set /a "LATENCY_MS=%%a*60+%%b"
        set "LATENCY=!LATENCY_MS!ms"
        goto :MirrorTestResult
    )
)

REM 如果都失败，设置一个高延迟值
set "LATENCY=9999ms"

:MirrorTestResult
echo [测试] %~2 - 延迟: %LATENCY%
exit /b

REM ============================================
REM 测试所有镜像源速度
REM ============================================
echo [1/7] 测试镜像源速度...
echo.

set "BEST_NPM_MIRROR="
set "BEST_NPM_NAME="
set "BEST_NPM_SPEED=99999"
set "BEST_NODE_MIRROR="
set "BEST_NODE_NAME="
set "BEST_NODE_SPEED=99999"

echo 测试 npm 镜像源...
for /f "tokens=1,2 delims=|" %%a in ('set NPM_MIRRORS[' 2^>nul') do (
    set "MIRROR_URL=%%a"
    set "MIRROR_NAME=%%b"
    
    REM 提取域名
    for /f "tokens=2 delims=/" %%x in ("%%a") do set "DOMAIN=%%x"
    
    REM 测试速度
    for /f "tokens=4 delims==,<>" %%i in ('ping -n 1 !DOMAIN! 2^>nul ^| findstr /i "平均"') do (
        set "LATENCY=%%i"
        REM 去掉 "ms" 后缀
        set "LATENCY=!LATENCY:ms=!"
        
        if !LATENCY! LSS !BEST_NPM_SPEED! (
            set "BEST_NPM_SPEED=!LATENCY!"
            set "BEST_NPM_MIRROR=!MIRROR_URL!"
            set "BEST_NPM_NAME=!MIRROR_NAME!"
        )
        
        echo [测试] %%b - !LATENCY!ms
    )
)

echo.
echo 测试 Node.js 下载镜像...
for /f "tokens=1,2 delims=|" %%a in ('set NODE_MIRRORS[' 2^>nul') do (
    set "MIRROR_URL=%%a"
    set "MIRROR_NAME=%%b"
    
    REM 提取域名
    for /f "tokens=2 delims=/" %%x in ("%%a") do set "DOMAIN=%%x"
    
    REM 测试速度
    for /f "tokens=4 delims==,<>" %%i in ('ping -n 1 !DOMAIN! 2^>nul ^| findstr /i "平均"') do (
        set "LATENCY=%%i"
        REM 去掉 "ms" 后缀
        set "LATENCY=!LATENCY:ms=!"
        
        if !LATENCY! LSS !BEST_NODE_SPEED! (
            set "BEST_NODE_SPEED=!LATENCY!"
            set "BEST_NODE_MIRROR=!MIRROR_URL!"
            set "BEST_NODE_NAME=!MIRROR_NAME!"
        )
        
        echo [测试] %%b - !LATENCY!ms
    )
)

echo.
echo ============================================
echo [选择] 最快的镜像源
echo ============================================
echo.
echo npm 镜像: %BEST_NPM_NAME% (%BEST_NPM_SPEED%ms)
echo Node.js 镜像: %BEST_NODE_NAME% (%BEST_NODE_SPEED%ms)
echo.

REM ============================================
REM 2. 检查 Node.js 是否已安装
REM ============================================
echo [2/7] 检查 Node.js...
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
    echo [使用] %BEST_NODE_NAME%
    
    REM 设置下载 URL（使用选定的最快镜像）
    set "NODE_URL=%BEST_NODE_MIRROR%v22.11.0/node-v22.11.0-x64.msi"
    
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
REM 3. 配置 npm 镜像源（永久生效）
REM ============================================
:check_npm
echo [3/7] 配置 npm 镜像源（永久生效）...
echo.

REM 1. 配置当前用户
echo [配置] 当前用户 npm 配置...
npm config set registry %BEST_NPM_MIRROR%
if %ERRORLEVEL% EQU 0 (
    echo [OK] npm 镜像源配置成功
) else (
    echo [警告] npm 镜像源配置失败
)

REM 2. 设置全局 npm 配置文件
echo [配置] 全局 npm 配置文件...
set "NPM_CONFIG_FILE=%APPDATA%\npm\etc\npmrc"
if not exist "%APPDATA%\npm" mkdir "%APPDATA%\npm"
if not exist "%APPDATA%\npm\etc" mkdir "%APPDATA%\npm\etc"

echo registry=%BEST_NPM_MIRROR% > "%NPM_CONFIG_FILE%"
echo [OK] 创建全局 npm 配置文件: %NPM_CONFIG_FILE%

REM 3. 配置 .npmrc 永久文件
echo [配置] 用户目录 .npmrc...
set "USER_NPMRC=%USERPROFILE%\.npmrc"
echo registry=%BEST_NPM_MIRROR% > "%USER_NPMRC%"
echo [OK] 创建用户 .npmrc: %USER_NPMRC%

echo.
echo [信息] 镜像源已永久配置，重启终端不会丢失
echo.

REM ============================================
REM 4. 配置环境变量（永久生效）
REM ============================================
echo [4/7] 配置环境变量...

REM 添加 Node.js 和 npm 到 PATH（永久）
echo [配置] PATH 环境变量...

REM 检查是否已经在 PATH 中
echo %PATH% | findstr /C:"%APPDATA%\npm" >nul
if %ERRORLEVEL% NEQ 0 (
    REM 使用 setx 设置永久环境变量
    setx PATH "%PATH%;%APPDATA%\npm" >nul 2>&1
    echo [OK] 已添加到 PATH（永久生效）
) else (
    echo [OK] PATH 已配置
)

REM 设置 NODE_MIRROR 环境变量（用于 nvm）
setx NODE_MIRROR "%BEST_NODE_MIRROR%" >nul 2>&1
echo [OK] NODE_MIRROR 已设置

REM 立即生效于当前会话
set "PATH=%PATH%;%APPDATA%\npm"
set "NODE_MIRROR=%BEST_NODE_MIRROR%"

echo.

REM ============================================
REM 5. 安装 OpenClaw
REM ============================================
echo [5/7] 安装 OpenClaw...
echo.

REM 检查全局安装
npm list -g openclaw >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [信息] OpenClaw 已安装，尝试更新...
    npm update -g openclaw
) else (
    echo [安装] 正在安装 OpenClaw...
    echo [使用] %BEST_NPM_NAME%
    npm install -g openclaw
)

if %ERRORLEVEL% NEQ 0 (
    echo [错误] OpenClaw 安装失败
    echo.
    echo 可能的原因：
    echo   1. 网络连接问题
    echo   2. 镜像源访问失败
    echo   3. 权限不足
    echo.
    echo 建议：
    echo   1. 检查网络连接
    echo   2. 尝试使用管理员权限运行
    echo   3. 查看镜像源速度: %BEST_NPM_SPEED%ms
    echo.
    pause
    exit /b 1
)

echo [OK] OpenClaw 安装完成
echo.

REM ============================================
REM 6. 验证安装
REM ============================================
echo [6/7] 验证安装...

REM 验证 openclaw 命令
where openclaw >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [警告] openclaw 命令未找到，尝试刷新环境变量...
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
for /f "tokens=*" %%i in ('openclaw --version 2^>nul') do set OPENCLAW_VERSION=%%i
if defined OPENCLAW_VERSION (
    echo [OK] OpenClaw 版本: !OPENCLAW_VERSION!
) else (
    echo [警告] 无法获取 OpenClaw 版本
)

echo.

REM ============================================
REM 7. 配置开机启动（可选）
REM ============================================
echo [7/7] 配置开机启动...
echo.

set /p AUTO_START="是否配置 OpenClaw Gateway 开机启动? (Y/N): "
if /i "%AUTO_START%"=="Y" (
    echo.
    echo [配置] 正在配置开机启动...
    
    REM 检查是否使用管理员权限
    net session >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        REM 使用注册表配置开机启动（推荐）
        echo [方式1] 添加到注册表启动项...
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OpenClawGateway" /t REG_SZ /d "openclaw gateway start" /f >nul 2>&1
        
        if %ERRORLEVEL% EQU 0 (
            echo [OK] 已添加到注册表启动项
            echo [位置] HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
        ) else (
            echo [备选] 注册表失败，使用启动文件夹...
            
            REM 方式2：添加到启动文件夹
            set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
            set "SHORTCUT_FILE=%STARTUP_FOLDER%\OpenClawGateway.bat"
            
            REM 创建启动脚本
            echo @echo off > "%SHORTCUT_FILE%"
            echo start /min openclaw gateway start >> "%SHORTCUT_FILE%"
            
            echo [OK] 已添加到启动文件夹
            echo [位置] %SHORTCUT_FILE%
        )
        
        echo.
        echo [信息] OpenClaw Gateway 将在下次开机时自动启动
        echo [提示] 如需取消开机启动，请运行:
        echo   reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OpenClawGateway" /f
        echo.
    ) else (
        echo [警告] 需要管理员权限才能配置开机启动
        echo.
        echo 请以管理员身份重新运行此脚本，或手动配置：
        echo   1. 注册表方式（推荐）:
        echo      reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OpenClawGateway" /t REG_SZ /d "openclaw gateway start" /f
        echo.
        echo   2. 启动文件夹方式:
        echo      创建快捷方式到: %%APPDATA%%\Microsoft\Windows\Start Menu\Programs\Startup\
        echo.
    )
)

echo.
echo ============================================
echo [成功] 安装完成！
echo ============================================
echo.
echo 安装信息：
echo   - OpenClaw 版本: !OPENCLAW_VERSION!
echo   - npm 镜像: %BEST_NPM_NAME% (%BEST_NPM_SPEED%ms)
echo   - Node.js 镜像: %BEST_NODE_NAME% (%BEST_NODE_SPEED%ms)
echo   - 永久配置: 是（重启终端不丢失）
echo.

if /i "%AUTO_START%"=="Y" (
    echo   - 开机启动: 已启用
)

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
echo 文档位置：
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
        
        REM 询问是否立即启动
        set /p START_GATEWAY="是否立即启动 Gateway? (Y/N): "
        if /i "!START_GATEWAY!"=="Y" (
            echo.
            echo [启动] 正在启动 OpenClaw Gateway...
            start /min openclaw gateway start
            echo [OK] Gateway 已在后台启动
            echo [查看] openclaw gateway status
        )
    ) else (
        echo [警告] 初始化失败，可以稍后手动运行: openclaw init
    )
)

echo.
echo ============================================
echo 配置文件位置：
echo   - npm 配置: %USER_NPMRC%
echo   - 全局配置: %NPM_CONFIG_FILE%
echo   - 环境变量: 已永久设置（使用 setx）
echo.
echo 感谢使用 OpenClaw！
echo ============================================
echo.

pause
endlocal

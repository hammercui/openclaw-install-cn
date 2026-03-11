@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  OpenClaw One-Click Installer for Windows
::  Version: 2.0.0
::  Optimized for China mainland network
::  Pure CMD - no PowerShell dependency
:: ============================================================

:: Force ASCII code page to prevent garbled output
chcp 437 >nul 2>nul

:: ============================================================
::  Configuration
:: ============================================================
set "VERSION=2.0.0"
set "NODE_TARGET=22"
set "NODE_MSI_VER=22.11.0"
set "LOG=%TEMP%\openclaw-install.log"

:: Default mirrors (overwritten if speed test succeeds)
set "BEST_NPM_MIRROR=https://registry.npmmirror.com"
set "BEST_NPM_NAME=Taobao"
set "BEST_NODE_MIRROR=https://npmmirror.com/mirrors/node/"
set "BEST_NODE_NAME=Taobao"

:: ============================================================
::  Init log
:: ============================================================
> "%LOG%" echo OpenClaw Windows Installer v%VERSION%
>> "%LOG%" echo Date: %DATE%  Time: %TIME%
>> "%LOG%" echo.

:: ============================================================
::  MAIN FLOW
:: ============================================================
call :Header
call :Step1
call :Step2
call :Step3
call :Step4
call :Step5
call :Step6
call :Step7
call :Summary
goto :EOF

:: ============================================================
::  Helper subroutines
:: ============================================================

:Log
>> "%LOG%" echo %~1
goto :eof

:Ok
echo [  OK  ] %~1
>> "%LOG%" echo [  OK  ] %~1
goto :eof

:Info
echo [ INFO ] %~1
>> "%LOG%" echo [ INFO ] %~1
goto :eof

:Warn
echo [ WARN ] %~1
>> "%LOG%" echo [ WARN ] %~1
goto :eof

:Err
echo [ERROR ] %~1
>> "%LOG%" echo [ERROR ] %~1
goto :eof

:PrintStep
echo.
echo ------------------------------------------------------------
echo  Step %~1 of 7 ^| %~2
echo ------------------------------------------------------------
>> "%LOG%" echo.
>> "%LOG%" echo ---- Step %~1 of 7: %~2 ----
goto :eof

:Header
echo.
echo ============================================================
echo   OpenClaw One-Click Installer for Windows  v%VERSION%
echo   Log: %LOG%
echo ============================================================
echo.
goto :eof

:: ============================================================
::  Step 1 - Test mirror speed and select fastest
:: ============================================================
:Step1
call :PrintStep 1 "Testing mirror speed"

where curl >nul 2>nul
if not errorlevel 1 goto :Step1_CurlTest

call :Warn "curl not available - skipping speed test, using default: Taobao"
goto :Step1_Done

:Step1_CurlTest
call :Info "Testing npm mirrors (first to respond wins)..."

curl -s -o nul --connect-timeout 4 --max-time 6 "https://registry.npmmirror.com" >nul 2>&1
if not errorlevel 1 (
    set "BEST_NPM_MIRROR=https://registry.npmmirror.com"
    set "BEST_NPM_NAME=Taobao"
    goto :Step1_NodeMirrors
)
call :Info "  Taobao npm   - no response"

curl -s -o nul --connect-timeout 4 --max-time 6 "https://mirrors.cloud.tencent.com/npm/" >nul 2>&1
if not errorlevel 1 (
    set "BEST_NPM_MIRROR=https://mirrors.cloud.tencent.com/npm/"
    set "BEST_NPM_NAME=Tencent"
    goto :Step1_NodeMirrors
)
call :Info "  Tencent npm  - no response"

curl -s -o nul --connect-timeout 4 --max-time 6 "https://mirrors.huaweicloud.com/repository/npm/" >nul 2>&1
if not errorlevel 1 (
    set "BEST_NPM_MIRROR=https://mirrors.huaweicloud.com/repository/npm/"
    set "BEST_NPM_NAME=Huawei"
    goto :Step1_NodeMirrors
)
call :Info "  Huawei npm   - no response"
call :Warn "All npm mirrors failed - using default: Taobao"

:Step1_NodeMirrors
call :Ok "npm mirror   : !BEST_NPM_NAME! (!BEST_NPM_MIRROR!)"
call :Info "Testing Node.js download mirrors..."

curl -s -o nul --connect-timeout 4 --max-time 6 "https://npmmirror.com/mirrors/node/" >nul 2>&1
if not errorlevel 1 (
    set "BEST_NODE_MIRROR=https://npmmirror.com/mirrors/node/"
    set "BEST_NODE_NAME=Taobao"
    goto :Step1_Done
)
call :Info "  Taobao node  - no response"

curl -s -o nul --connect-timeout 4 --max-time 6 "https://mirrors.cloud.tencent.com/nodejs-release/" >nul 2>&1
if not errorlevel 1 (
    set "BEST_NODE_MIRROR=https://mirrors.cloud.tencent.com/nodejs-release/"
    set "BEST_NODE_NAME=Tencent"
    goto :Step1_Done
)
call :Info "  Tencent node - no response"

curl -s -o nul --connect-timeout 4 --max-time 6 "https://mirrors.huaweicloud.com/nodejs/" >nul 2>&1
if not errorlevel 1 (
    set "BEST_NODE_MIRROR=https://mirrors.huaweicloud.com/nodejs/"
    set "BEST_NODE_NAME=Huawei"
    goto :Step1_Done
)
call :Info "  Huawei node  - no response"
call :Warn "All node mirrors failed - using default: Taobao"

:Step1_Done
call :Ok "Node mirror  : !BEST_NODE_NAME! (!BEST_NODE_MIRROR!)"
>> "%LOG%" echo npm  mirror: !BEST_NPM_NAME!  !BEST_NPM_MIRROR!
>> "%LOG%" echo node mirror: !BEST_NODE_NAME! !BEST_NODE_MIRROR!
goto :eof

:: ============================================================
::  Step 2 - Check / Install Node.js
:: ============================================================
:Step2
call :PrintStep 2 "Checking Node.js"

where node >nul 2>nul
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('node -v 2^>nul') do set "NODE_VER=%%v"
    call :Ok "Node.js already installed: !NODE_VER!"
    goto :Step2_Done
)

call :Info "Node.js not found, installing..."

:: Check for nvm-windows
where nvm >nul 2>nul
if not errorlevel 1 (
    call :Info "Found nvm-windows - installing Node.js %NODE_TARGET% via nvm..."
    set "NVM_NODEJS_ORG_MIRROR=!BEST_NODE_MIRROR!"
    nvm install %NODE_TARGET% >> "%LOG%" 2>&1
    nvm use %NODE_TARGET% >> "%LOG%" 2>&1
    if errorlevel 1 (
        call :Err "nvm install failed - see log: %LOG%"
        pause
        exit /b 1
    )
    call :Ok "Node.js %NODE_TARGET% installed via nvm"
    goto :Step2_Refresh
)

:: Download and install Node.js MSI
set "NODE_URL=!BEST_NODE_MIRROR!v%NODE_MSI_VER%/node-v%NODE_MSI_VER%-x64.msi"
set "NODE_MSI=%TEMP%\node-v%NODE_MSI_VER%-x64.msi"

call :Info "Downloading Node.js %NODE_MSI_VER% from !BEST_NODE_NAME!..."
call :Info "URL: !NODE_URL!"

curl -L --progress-bar -o "!NODE_MSI!" "!NODE_URL!" 2>> "%LOG%"
if errorlevel 1 (
    call :Warn "curl download failed, trying bitsadmin..."
    bitsadmin /transfer node_dl /download /priority FOREGROUND "!NODE_URL!" "!NODE_MSI!" >> "%LOG%" 2>&1
    if errorlevel 1 (
        call :Err "Download failed"
        call :Err "Manual download: !NODE_URL!"
        del "!NODE_MSI!" >nul 2>&1
        pause
        exit /b 1
    )
)

call :Info "Installing Node.js %NODE_MSI_VER% (silent)..."
msiexec /i "!NODE_MSI!" /quiet /norestart ADDLOCAL=ALL >> "%LOG%" 2>&1
if errorlevel 1 (
    call :Err "MSI install failed - see log: %LOG%"
    del "!NODE_MSI!" >nul 2>&1
    pause
    exit /b 1
)

del "!NODE_MSI!" >nul 2>&1
call :Ok "Node.js %NODE_MSI_VER% installed"

:Step2_Refresh
:: Refresh PATH in current session so node is immediately usable
set "PATH=%PATH%;C:\Program Files\nodejs;%APPDATA%\npm"
timeout /t 3 /nobreak >nul

:Step2_Done
for /f "tokens=*" %%v in ('node -v 2^>nul') do set "NODE_VER=%%v"
call :Log "Node.js version: !NODE_VER!"
goto :eof

:: ============================================================
::  Step 3 - Configure npm registry (permanent)
:: ============================================================
:Step3
call :PrintStep 3 "Configuring npm registry"

npm config set registry !BEST_NPM_MIRROR! >> "%LOG%" 2>&1
call :Ok "npm config set registry -> !BEST_NPM_NAME!"

:: Write user-level .npmrc
set "USER_NPMRC=%USERPROFILE%\.npmrc"
> "!USER_NPMRC!" echo registry=!BEST_NPM_MIRROR!
call :Ok "Written: !USER_NPMRC!"

:: Write global .npmrc
set "GLOBAL_NPMRC=%APPDATA%\npm\etc\npmrc"
if not exist "%APPDATA%\npm\etc" mkdir "%APPDATA%\npm\etc" >nul 2>&1
> "!GLOBAL_NPMRC!" echo registry=!BEST_NPM_MIRROR!
call :Ok "Written: !GLOBAL_NPMRC!"

call :Info "Registry config is permanent - survives terminal restarts"
goto :eof

:: ============================================================
::  Step 4 - Configure environment variables (permanent)
:: ============================================================
:Step4
call :PrintStep 4 "Configuring environment variables"

:: Add %APPDATA%\npm to user PATH
echo !PATH! | findstr /c:"%APPDATA%\npm" >nul
if errorlevel 1 (
    setx PATH "!PATH!;%APPDATA%\npm" >nul 2>&1
    call :Ok "Added %%APPDATA%%\npm to user PATH (permanent)"
) else (
    call :Info "PATH already contains %%APPDATA%%\npm"
)

:: Set NODE_MIRROR for nvm
setx NODE_MIRROR "!BEST_NODE_MIRROR!" >nul 2>&1
call :Ok "NODE_MIRROR set to !BEST_NODE_NAME! (permanent)"

:: Apply to current session immediately
set "PATH=!PATH!;%APPDATA%\npm"
set "NODE_MIRROR=!BEST_NODE_MIRROR!"
goto :eof

:: ============================================================
::  Step 5 - Install OpenClaw
:: ============================================================
:Step5
call :PrintStep 5 "Installing OpenClaw"

call :Info "Registry: !BEST_NPM_MIRROR!"

npm list -g openclaw >nul 2>&1
if not errorlevel 1 (
    call :Info "OpenClaw already installed - updating..."
    npm update -g openclaw >> "%LOG%" 2>&1
) else (
    call :Info "Running: npm install -g openclaw"
    npm install -g openclaw >> "%LOG%" 2>&1
)

if errorlevel 1 (
    call :Err "OpenClaw installation failed"
    echo.
    echo  Troubleshooting:
    echo    1. Run this script as Administrator
    echo    2. Test network: curl !BEST_NPM_MIRROR!
    echo    3. Retry manually: npm install -g openclaw
    echo    4. Full log: %LOG%
    echo.
    pause
    exit /b 1
)

call :Ok "OpenClaw installed"
goto :eof

:: ============================================================
::  Step 6 - Verify installation
:: ============================================================
:Step6
call :PrintStep 6 "Verifying installation"

:: Refresh PATH with npm global dir
set "PATH=!PATH!;%APPDATA%\npm"

where openclaw >nul 2>nul
if errorlevel 1 (
    call :Warn "openclaw not in PATH yet - trying registry refresh..."
    for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USR_PATH=%%b"
    set "PATH=!USR_PATH!;%APPDATA%\npm"
    where openclaw >nul 2>nul
    if errorlevel 1 (
        call :Err "openclaw command not found"
        call :Err "Please restart CMD then run: openclaw --version"
        call :Err "If still missing, ensure %%APPDATA%%\npm is in PATH"
        pause
        exit /b 1
    )
)

for /f "tokens=*" %%v in ('openclaw --version 2^>nul') do set "OC_VERSION=%%v"
call :Ok "openclaw !OC_VERSION! is ready"
call :Log "openclaw version: !OC_VERSION!"
goto :eof

:: ============================================================
::  Step 7 - Auto-start configuration (optional)
:: ============================================================
:Step7
call :PrintStep 7 "Auto-start configuration (optional)"

set /p "DO_AUTOSTART=Configure OpenClaw Gateway to auto-start at login? [Y/N]: "
if /i not "!DO_AUTOSTART!"=="Y" (
    call :Info "Skipping auto-start"
    goto :eof
)

:: Attempt registry method
call :Info "Adding to registry startup entries..."
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" ^
    /v "OpenClawGateway" /t REG_SZ ^
    /d "openclaw gateway start" /f >nul 2>&1

if not errorlevel 1 (
    call :Ok "Registry startup entry added"
    call :Info "  Key  : HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    call :Info "  Name : OpenClawGateway"
    call :Info "  Remove: reg delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v OpenClawGateway /f"
    goto :eof
)

:: Fallback: Startup folder
call :Warn "Registry failed - using Startup folder..."
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "AUTORUN_FILE=!STARTUP_DIR!\OpenClawGateway.bat"

> "!AUTORUN_FILE!" echo @echo off
>> "!AUTORUN_FILE!" echo start /min "" openclaw gateway start

call :Ok "Startup script created: !AUTORUN_FILE!"
call :Info "  Remove: del ""!AUTORUN_FILE!"""
goto :eof

:: ============================================================
::  Summary + optional init/start
:: ============================================================
:Summary
echo.
echo ============================================================
echo   Installation Complete!
echo ============================================================
echo.
echo   OpenClaw    : !OC_VERSION!
echo   Node.js     : !NODE_VER!
echo   npm mirror  : !BEST_NPM_NAME! (!BEST_NPM_MIRROR!)
echo   Node mirror : !BEST_NODE_NAME! (!BEST_NODE_MIRROR!)
echo   npm config  : %USERPROFILE%\.npmrc
echo   Log file    : %LOG%
echo.
echo   Next steps:
echo     openclaw init             - Initialize configuration
echo     openclaw gateway start    - Start the Gateway
echo     openclaw gateway status   - Check Gateway status
echo     openclaw --help           - Show all commands
echo.
echo ============================================================
echo.

>> "%LOG%" echo.
>> "%LOG%" echo Installation Complete: %DATE% %TIME%
>> "%LOG%" echo OpenClaw: !OC_VERSION!

set /p "DO_INIT=Initialize OpenClaw now? [Y/N]: "
if /i "!DO_INIT!"=="Y" (
    echo.
    call :Info "Running: openclaw init"
    openclaw init
    if not errorlevel 1 (
        call :Ok "Initialization complete"
        echo.
        set /p "DO_START=Start Gateway now? [Y/N]: "
        if /i "!DO_START!"=="Y" (
            call :Info "Starting Gateway in background..."
            start /min "" openclaw gateway start
            timeout /t 2 /nobreak >nul
            openclaw gateway status
        )
    ) else (
        call :Warn "Init failed - run manually: openclaw init"
    )
)

echo.
echo Log saved to: %LOG%
echo.
pause
endlocal
goto :eof

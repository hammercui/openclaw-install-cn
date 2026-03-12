@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  OpenClaw One-Click Installer for Windows (Main Entry)
::  Version: 3.0.0 - Modular Architecture
::  Pure CMD - no PowerShell dependency
:: ============================================================

chcp 437 >nul 2>nul

:: ============================================================
::  Configuration
:: ============================================================
set "VERSION=3.0.0"
set "LOG=%TEMP%\openclaw-install.log"
set "SCRIPT_DIR=%~dp0"

:: Init log
> "%LOG%" echo OpenClaw Windows Installer v%VERSION%
>> "%LOG%" echo Date: %DATE%  Time: %TIME%
>> "%LOG%" echo Modular install - main entry
>> "%LOG%" echo.

:: ============================================================
::  Header
:: ============================================================
echo.
echo ============================================================
echo   OpenClaw One-Click Installer for Windows
echo   Version: %VERSION%
echo   Optimized for China mainland network
echo ============================================================
echo.
echo  This installer will:
echo    - Test and configure fastest mirror
echo    - Install Git, Node.js, pnpm
echo    - Install OpenClaw CLI
echo    - Configure auto-start
echo.
echo  Log file: %LOG%
echo ============================================================
echo.

:: ============================================================
::  Check Admin Rights
:: ============================================================
net session >nul 2>&1
if errorlevel 1 (
    set "IS_ADMIN=0"
    echo [ INFO ] Running as standard user - will use user-space paths
) else (
    set "IS_ADMIN=1"
    echo [  OK  ] Running as Administrator
)

:: Export for child scripts
set "IS_ADMIN=%IS_ADMIN%"

:: ============================================================
::  Stage 1: Mirror Test + Environment Variables
:: ============================================================
echo.
echo ============================================================
echo   STAGE 1/4: Testing mirrors and configuring environment
echo ============================================================
call "%SCRIPT_DIR%install-step1-mirror.bat"
if errorlevel 1 (
    echo.
    echo [ERROR] Stage 1 failed - see log: %LOG%
    pause
    exit /b 1
)

:: ============================================================
::  Stage 2: Install Base Tools (Git, Node.js, pnpm)
:: ============================================================
echo.
echo ============================================================
echo   STAGE 2/4: Installing base tools
echo ============================================================
call "%SCRIPT_DIR%install-step2-tools.bat"
if errorlevel 1 (
    echo.
    echo [ERROR] Stage 2 failed - see log: %LOG%
    pause
    exit /b 1
)

:: ============================================================
::  Stage 3: Install OpenClaw
:: ============================================================
echo.
echo ============================================================
echo   STAGE 3/4: Installing OpenClaw
echo ============================================================
call "%SCRIPT_DIR%install-step3-openclaw.bat"
if errorlevel 1 (
    echo.
    echo [ERROR] Stage 3 failed - see log: %LOG%
    pause
    exit /b 1
)

:: ============================================================
::  Stage 4: Verify + Auto-start
:: ============================================================
echo.
echo ============================================================
echo   STAGE 4/4: Verification and configuration
echo ============================================================
call "%SCRIPT_DIR%install-step4-verify.bat"
if errorlevel 1 (
    echo.
    echo [ERROR] Stage 4 failed - see log: %LOG%
    pause
    exit /b 1
)

:: ============================================================
::  Complete
:: ============================================================
echo.
echo ============================================================
echo   Installation Complete!
echo ============================================================
echo.
echo   All stages completed successfully.
echo   Log saved to: %LOG%
echo.
pause
endlocal
exit /b 0


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
::  Step Git - Check git (required by some npm dependencies)
:: ============================================================
:StepGit
call :PrintStep 2 "Checking git"

where git >nul 2>nul
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('git --version 2^>nul') do set "GIT_VER=%%v"
    call :Ok "git already installed: !GIT_VER!"
    goto :eof
)

call :Warn "git not found - downloading and installing automatically..."

:: Download installer from npmmirror (Git for Windows mirror, China accessible)
call :Info "Detecting latest Git for Windows version..."
set "GIT_VER_NUM=2.48.1"
set "GIT_URL=https://registry.npmmirror.com/-/binary/git-for-windows/v%GIT_VER_NUM%.windows.1/Git-%GIT_VER_NUM%-64-bit.exe"
set "GIT_INSTALLER=%TEMP%\git-installer.exe"

call :Info "Downloading Git %GIT_VER_NUM% from npmmirror..."
call :Info "URL: !GIT_URL!"
curl -L -# -o "!GIT_INSTALLER!" "!GIT_URL!"
if errorlevel 1 (
    call :Warn "curl failed, trying bitsadmin..."
    bitsadmin /transfer git_dl /download /priority FOREGROUND "!GIT_URL!" "!GIT_INSTALLER!" >> "%LOG%" 2>&1
    if errorlevel 1 (
        call :Err "Git download failed"
        call :Err "Please install git manually: https://git-scm.com/download/win"
        pause
        exit /b 1
    )
)

:: Verify file size
for %%A in ("!GIT_INSTALLER!") do set "GSIZE=%%~zA"
if !GSIZE! LSS 10000000 (
    call :Err "Git installer too small (!GSIZE! bytes) - download corrupted"
    del "!GIT_INSTALLER!" >nul 2>&1
    pause
    exit /b 1
)
call :Ok "Downloaded !GSIZE! bytes"

call :Info "Installing Git (a progress window will appear)..."
:: /CURRENTUSER allows install without admin rights (installs to %LOCALAPPDATA%\Programs\Git)
"!GIT_INSTALLER!" /VERYSILENT /NORESTART /NOCANCEL ^
    /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /CURRENTUSER ^
    /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
del "!GIT_INSTALLER!" >nul 2>&1

:: Refresh PATH - cover both system-wide and per-user install locations
set "PATH=!PATH!;C:\Program Files\Git\cmd;C:\Program Files\Git\bin"
set "PATH=!PATH!;!LOCALAPPDATA!\Programs\Git\cmd;!LOCALAPPDATA!\Programs\Git\bin"

where git >nul 2>nul
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('git --version 2^>nul') do set "GIT_VER=%%v"
    call :Ok "git installed: !GIT_VER!"
    goto :eof
)

call :Err "git still not found after installation"
call :Err "Please restart this script - git PATH may need a new CMD session"
pause
exit /b 1

:: ============================================================
::  Step 2 - Check / Install Node.js
:: ============================================================
:Step2
call :PrintStep 3 "Checking Node.js"

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

:: Choose install method based on admin rights
if "!IS_ADMIN!"=="1" goto :Step2_MSI

:: ---- Non-admin: portable ZIP ----
:Step2_Portable
set "NODE_ZIP_URL=!BEST_NODE_MIRROR!v%NODE_MSI_VER%/node-v%NODE_MSI_VER%-win-x64.zip"
set "NODE_ZIP=%TEMP%\node-v%NODE_MSI_VER%-win-x64.zip"
set "NODE_PORTABLE=!LOCALAPPDATA!\Programs\nodejs"

call :Info "No admin - using portable Node.js ZIP (no UAC required)"
call :Info "Downloading Node.js %NODE_MSI_VER% from !BEST_NODE_NAME!..."
call :Info "URL: !NODE_ZIP_URL!"

curl -L -# -o "!NODE_ZIP!" "!NODE_ZIP_URL!" 2>> "%LOG%"
if errorlevel 1 (
    call :Warn "curl failed, trying bitsadmin..."
    bitsadmin /transfer node_dl /download /priority FOREGROUND "!NODE_ZIP_URL!" "!NODE_ZIP!" >> "%LOG%" 2>&1
    if errorlevel 1 (
        call :Err "Download failed"
        call :Err "Manual download: !NODE_ZIP_URL!"
        pause
        exit /b 1
    )
)
for %%A in ("!NODE_ZIP!") do set "FSIZE=%%~zA"
if !FSIZE! LSS 5000000 (
    call :Err "ZIP too small (!FSIZE! bytes) - corrupted download"
    del "!NODE_ZIP!" >nul 2>&1
    pause
    exit /b 1
)
call :Ok "Downloaded !FSIZE! bytes"

call :Info "Extracting to !NODE_PORTABLE!..."
if not exist "!NODE_PORTABLE!" mkdir "!NODE_PORTABLE!" >nul 2>&1
:: Extract ZIP using built-in tar (Windows 10 1803+)
tar -xf "!NODE_ZIP!" -C "%TEMP%" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :Err "ZIP extraction failed"
    del "!NODE_ZIP!" >nul 2>&1
    pause
    exit /b 1
)
:: Move extracted folder contents to target dir
for /d %%D in ("%TEMP%\node-v%NODE_MSI_VER%-win-x64") do (
    xcopy /e /y /q "%%D\*" "!NODE_PORTABLE!\" >nul 2>&1
    rmdir /s /q "%%D" >nul 2>&1
)
del "!NODE_ZIP!" >nul 2>&1

:: Add portable path to user PATH
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USR_PATH=%%b"
if not defined USR_PATH set "USR_PATH="
> "%TEMP%\_oc_nodecheck.tmp" echo !USR_PATH!
findstr /i /c:"nodejs" "%TEMP%\_oc_nodecheck.tmp" >nul 2>&1
del "%TEMP%\_oc_nodecheck.tmp" >nul 2>&1
if errorlevel 1 (
    setx PATH "!USR_PATH!;!NODE_PORTABLE!" >nul 2>&1
    call :Ok "Added !NODE_PORTABLE! to user PATH (permanent)"
)
set "PATH=!PATH!;!NODE_PORTABLE!"
call :Ok "Portable Node.js installed to !NODE_PORTABLE!"
goto :Step2_Refresh

:: ---- Admin: MSI installer ----
:Step2_MSI
set "NODE_URL=!BEST_NODE_MIRROR!v%NODE_MSI_VER%/node-v%NODE_MSI_VER%-x64.msi"
set "NODE_MSI=%TEMP%\node-v%NODE_MSI_VER%-x64.msi"

call :Info "Downloading Node.js %NODE_MSI_VER% from !BEST_NODE_NAME!..."
call :Info "URL: !NODE_URL!"

curl -L -# -o "!NODE_MSI!" "!NODE_URL!" 2>> "%LOG%"
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

if not exist "!NODE_MSI!" (
    call :Err "File not found after download: !NODE_MSI!"
    pause
    exit /b 1
)
for %%A in ("!NODE_MSI!") do set "FSIZE=%%~zA"
if !FSIZE! LSS 1000000 (
    call :Err "Downloaded file is too small (!FSIZE! bytes) - corrupted"
    del "!NODE_MSI!" >nul 2>&1
    pause
    exit /b 1
)
call :Ok "Downloaded !FSIZE! bytes -> !NODE_MSI!"

set "MSI_LOG=%TEMP%\node-msi-install.log"
call :Info "Installing Node.js %NODE_MSI_VER% (a progress window will appear)..."
msiexec /i "!NODE_MSI!" /passive /norestart /l*v "!MSI_LOG!"
if errorlevel 1 (
    call :Err "MSI install failed (exit code: !ERRORLEVEL!)"
    call :Err "MSI log  : !MSI_LOG!"
    call :Err "Install log: %LOG%"
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
::  Step 3 - Configure npm registry + prefix (permanent)
:: ============================================================
:Step3
call :PrintStep 4 "Configuring npm registry"

:: Lock npm global prefix to user directory.
:: Without this, npm might install to C:\Program Files\nodejs (system path)
:: which causes PATH issues. Always pin to APPDATA regardless of admin state.
set "NPM_PREFIX=%APPDATA%\npm"
if not exist "!NPM_PREFIX!" mkdir "!NPM_PREFIX!" >nul 2>&1

:: Write user-level .npmrc (registry + prefix)
set "USER_NPMRC=%USERPROFILE%\.npmrc"
> "!USER_NPMRC!" echo registry=!BEST_NPM_MIRROR!
>> "!USER_NPMRC!" echo prefix=!NPM_PREFIX!
call :Ok "Written: !USER_NPMRC! (registry + prefix)"

:: Write global .npmrc as well
set "GLOBAL_NPMRC=!NPM_PREFIX!\etc\npmrc"
if not exist "!NPM_PREFIX!\etc" mkdir "!NPM_PREFIX!\etc" >nul 2>&1
> "!GLOBAL_NPMRC!" echo registry=!BEST_NPM_MIRROR!
>> "!GLOBAL_NPMRC!" echo prefix=!NPM_PREFIX!
call :Ok "Written: !GLOBAL_NPMRC! (registry + prefix)"

call :Info "npm global prefix pinned to: !NPM_PREFIX!"
call :Info "Registry config is permanent - survives terminal restarts"
goto :eof

:: ============================================================
::  Step 4 - Configure environment variables (permanent)
:: ============================================================
:Step4
call :PrintStep 5 "Configuring environment variables"

:: NPM_PREFIX was set in Step3 - use it directly (no need to re-detect)
call :Info "npm global prefix: !NPM_PREFIX!"

:: Read user PATH from registry (avoids setx 1024-char limit on full %%PATH%%)
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USR_PATH=%%b"
if not defined USR_PATH set "USR_PATH="

:: Write USR_PATH to temp file then search - avoids findstr interpreting \n as newline
> "%TEMP%\_oc_pathcheck.tmp" echo !USR_PATH!
findstr /i /c:"npm" "%TEMP%\_oc_pathcheck.tmp" >nul 2>&1
del "%TEMP%\_oc_pathcheck.tmp" >nul 2>&1
if errorlevel 1 (
    setx PATH "!USR_PATH!;!NPM_PREFIX!" >nul 2>&1
    call :Ok "Added !NPM_PREFIX! to user PATH (permanent)"
) else (
    call :Info "PATH already contains npm path"
)

:: Set NODE_MIRROR for nvm
setx NODE_MIRROR "!BEST_NODE_MIRROR!" >nul 2>&1
call :Ok "NODE_MIRROR set to !BEST_NODE_NAME! (permanent)"

:: Apply to current session immediately
set "PATH=!PATH!;!NPM_PREFIX!"
set "NODE_MIRROR=!BEST_NODE_MIRROR!"
goto :eof

:: ============================================================
::  Step 5 - Install OpenClaw
:: ============================================================
:Step5
call :PrintStep 6 "Installing OpenClaw"

call :Info "Registry: !BEST_NPM_MIRROR!"

:: ---- Prefer pnpm (more reliable for packages with git/binary deps) ----
where pnpm >nul 2>nul
if not errorlevel 1 (
    call :Info "pnpm detected - using pnpm for installation"
    goto :Step5_Pnpm
)

call :Info "pnpm not found - installing pnpm via npm first..."
npm install -g pnpm --registry !BEST_NPM_MIRROR!
if errorlevel 1 (
    call :Warn "pnpm install failed - falling back to npm"
    goto :Step5_Npm
)
call :Ok "pnpm installed"

:: Run pnpm setup to configure PNPM_HOME and add to PATH
call :Info "Configuring pnpm environment (pnpm setup)..."
pnpm setup >> "%LOG%" 2>&1
if not errorlevel 1 (
    :: Refresh PATH from registry to get PNPM_HOME immediately
    for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "PATH=%%b;!PATH!"
    for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PNPM_HOME 2^>nul') do set "PNPM_HOME=%%b"
    if defined PNPM_HOME (
        set "PATH=!PNPM_HOME!;!PATH!"
        call :Ok "pnpm setup complete - PNPM_HOME: !PNPM_HOME!"
    )
)

:Step5_Pnpm
where openclaw >nul 2>nul
if not errorlevel 1 (
    call :Info "OpenClaw already installed - updating..."
    pnpm update -g openclaw
    goto :Step5_Done
)
call :Info "Running: pnpm install -g openclaw@latest --force"
pnpm install -g openclaw@latest --force
if errorlevel 1 (
    call :Warn "pnpm failed - falling back to npm"
    goto :Step5_Npm
)
goto :Step5_Done

:Step5_Npm
where openclaw >nul 2>nul
if not errorlevel 1 (
    call :Info "OpenClaw already installed - updating..."
    npm update -g openclaw --registry !BEST_NPM_MIRROR!
    goto :Step5_Done
)
call :Info "Running: npm install -g openclaw@latest"
npm install -g openclaw@latest --registry !BEST_NPM_MIRROR!
if errorlevel 1 (
    call :Err "OpenClaw installation failed"
    echo.
    echo  Troubleshooting:
    echo    1. Ensure git is installed: where git
    echo    2. Test registry: curl !BEST_NPM_MIRROR!
    echo    3. Full log: %LOG%
    echo.
    pause
    exit /b 1
)

:Step5_Done
call :Ok "OpenClaw installed"

:: Re-detect npm prefix after install
for /f "tokens=*" %%p in ('npm config get prefix 2^>nul') do set "NPM_PREFIX=%%p"
call :Info "npm prefix (post-install): !NPM_PREFIX!"

:: Scan known locations for openclaw.cmd
set "OC_BIN_DIR="
if exist "!NPM_PREFIX!\openclaw.cmd"                  set "OC_BIN_DIR=!NPM_PREFIX!"
if exist "C:\Program Files\nodejs\openclaw.cmd"       set "OC_BIN_DIR=C:\Program Files\nodejs"
if exist "C:\Program Files (x86)\nodejs\openclaw.cmd" set "OC_BIN_DIR=C:\Program Files (x86)\nodejs"

:: pnpm global bin directory
for /f "tokens=*" %%p in ('pnpm bin -g 2^>nul') do (
    set "PNPM_BIN=%%p"
    if exist "%%p\openclaw.cmd" set "OC_BIN_DIR=%%p"
)

if defined OC_BIN_DIR (
    call :Ok "openclaw.cmd found at: !OC_BIN_DIR!"
) else (
    call :Warn "openclaw.cmd not found in standard paths"
    call :Warn "This usually means the package was installed locally (missing -g flag)"
    set "OC_BIN_DIR=!NPM_PREFIX!"
)

:: Refresh PATH with all possible locations
set "PATH=!PATH!;!NPM_PREFIX!;!OC_BIN_DIR!"
if defined PNPM_BIN set "PATH=!PATH!;!PNPM_BIN!"
if defined PNPM_HOME set "PATH=!PATH!;!PNPM_HOME!"
set "PATH=!PATH!;C:\Program Files\nodejs;C:\Program Files (x86)\nodejs"
set "PATH=!PATH!;!LOCALAPPDATA!\Programs\nodejs"
call :Info "PATH refreshed in current session"
goto :eof

:: ============================================================
::  Step 6 - Verify installation
:: ============================================================
:Step6
call :PrintStep 7 "Verifying installation"

:: Ensure all candidate npm bin paths are in current session PATH
set "PATH=!PATH!;!NPM_PREFIX!;!OC_BIN_DIR!;C:\Program Files\nodejs;C:\Program Files (x86)\nodejs"

where openclaw >nul 2>nul
if errorlevel 1 (
    call :Warn "openclaw still not in PATH - running full diagnostic..."
    echo.
    echo  npm prefix : !NPM_PREFIX!
    echo  Detected   : !OC_BIN_DIR!
    echo.
    echo  --- Files in npm prefix ---
    dir "!NPM_PREFIX!\openclaw*" 2>nul || echo   none
    echo  --- Files in C:\Program Files\nodejs ---
    dir "C:\Program Files\nodejs\openclaw*" 2>nul || echo   none
    echo  --- openclaw in node_modules ---
    if exist "!NPM_PREFIX!\node_modules\openclaw" (
        echo   Package dir: !NPM_PREFIX!\node_modules\openclaw
        if exist "!NPM_PREFIX!\node_modules\openclaw\bin" (
            echo   bin/ directory EXISTS
            dir "!NPM_PREFIX!\node_modules\openclaw\bin\*" 2>nul
        ) else (
            echo   bin/ directory MISSING - package may have broken structure
        )
        if exist "!NPM_PREFIX!\node_modules\openclaw\package.json" (
            findstr /i "bin" "!NPM_PREFIX!\node_modules\openclaw\package.json" 2>nul
        )
    ) else (
        echo   Package dir NOT found - install likely failed
    )
    echo.
    echo  SOLUTION: Reinstall with npm (more reliable bin linking)
    echo    npm uninstall -g openclaw
    echo    npm install -g openclaw@latest --registry !BEST_NPM_MIRROR!
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('openclaw --version 2^>nul') do set "OC_VERSION=%%v"
call :Ok "openclaw !OC_VERSION! is ready"
call :Log "openclaw version: !OC_VERSION!"
goto :eof

:: ============================================================
::  Step 7 - Auto-start configuration (optional)
:: ============================================================
:Step7
call :PrintStep 8 "Auto-start configuration (optional)"

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

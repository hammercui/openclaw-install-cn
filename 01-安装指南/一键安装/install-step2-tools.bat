@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  Stage 2: Install Base Tools (Git, Node.js, pnpm)
:: ============================================================

if not defined LOG set "LOG=%TEMP%\openclaw-install.log"
if not defined IS_ADMIN set "IS_ADMIN=0"
if not defined BEST_NODE_MIRROR set "BEST_NODE_MIRROR=https://npmmirror.com/mirrors/node/"
if not defined BEST_NPM_MIRROR set "BEST_NPM_MIRROR=https://registry.npmmirror.com"
if not defined NPM_PREFIX set "NPM_PREFIX=%APPDATA%\npm"

set "NODE_TARGET=22"
set "NODE_MSI_VER=22.22.1"

call :Main
exit /b !ERRORLEVEL!

:: ============================================================
::  Helper Functions
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

:: ============================================================
::  Main Flow
:: ============================================================
:Main
call :Info "Stage 2: Installing base tools (Git, Node.js, pnpm)"
echo.

:: ---- Install Git ----
call :Info "Step 2.1: Checking Git..."
where git >nul 2>nul
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('git --version 2^>nul') do set "GIT_VER=%%v"
    call :Ok "Git already installed: !GIT_VER!"
    :: Ensure git HTTPS config is set even if git was pre-installed
    git config --global url."https://github.com/".insteadOf "git@github.com:" >> "%LOG%" 2>&1
    git config --global url."https://".insteadOf "git://" >> "%LOG%" 2>&1
    goto :InstallNode
)

call :Warn "Git not found - downloading and installing..."
set "GIT_VER_NUM=2.48.1"
set "GIT_URL=https://registry.npmmirror.com/-/binary/git-for-windows/v%GIT_VER_NUM%.windows.1/Git-%GIT_VER_NUM%-64-bit.exe"
set "GIT_INSTALLER=%TEMP%\git-installer.exe"

call :Info "Downloading Git %GIT_VER_NUM%..."
curl -L -# -o "%GIT_INSTALLER%" "%GIT_URL%"
if errorlevel 1 (
    bitsadmin /transfer git_dl /download /priority FOREGROUND "%GIT_URL%" "%GIT_INSTALLER%" >> "%LOG%" 2>&1
    if errorlevel 1 (
        call :Err "Git download failed"
        exit /b 1
    )
)

for %%A in ("%GIT_INSTALLER%") do set "GSIZE=%%~zA"
if !GSIZE! LSS 10000000 (
    call :Err "Git installer too small (!GSIZE! bytes)"
    del "%GIT_INSTALLER%" >nul 2>&1
    exit /b 1
)
call :Ok "Downloaded !GSIZE! bytes"

call :Info "Installing Git (progress window will appear)..."
"%GIT_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /CURRENTUSER ^
    /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS ^
    /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
del "%GIT_INSTALLER%" >nul 2>&1

set "PATH=%PATH%;C:\Program Files\Git\cmd;%LOCALAPPDATA%\Programs\Git\cmd"
where git >nul 2>nul
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('git --version 2^>nul') do set "GIT_VER=%%v"
    call :Ok "Git installed: !GIT_VER!"
) else (
    call :Err "Git still not found - PATH may need CMD restart"
    exit /b 1
)

:: Configure git to use HTTPS instead of SSH for GitHub (prevents SSH key issues)
call :Info "Configuring git to use HTTPS for GitHub (prevents SSH errors)..."
git config --global url."https://github.com/".insteadOf "git@github.com:" >> "%LOG%" 2>&1
git config --global url."https://".insteadOf "git://" >> "%LOG%" 2>&1
call :Ok "Git configured for HTTPS access"

:: ---- Install Node.js ----
:InstallNode
echo.
call :Info "Step 2.2: Checking Node.js..."
where node >nul 2>nul
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('node -v 2^>nul') do set "NODE_VER=%%v"
    call :Ok "Node.js detected: !NODE_VER!"
    
    :: Parse version - remove 'v' prefix and extract major.minor
    set "VER_NUM=!NODE_VER:~1!"
    for /f "tokens=1,2 delims=." %%a in ("!VER_NUM!") do (
        set "NODE_MAJOR=%%a"
        set "NODE_MINOR=%%b"
    )
    
    :: Check if version >= 22.22
    set "VERSION_OK=0"
    if !NODE_MAJOR! GTR 22 set "VERSION_OK=1"
    if !NODE_MAJOR! EQU 22 if !NODE_MINOR! GEQ 22 set "VERSION_OK=1"

    if "!VERSION_OK!"=="1" (
        call :Ok "Version check passed (requires v22.22.1+)"
        goto :InstallPnpm
    ) else (
        call :Warn "Node.js !NODE_VER! is too old (requires v22.22.1+)"
        call :Info "Will upgrade to Node.js %NODE_MSI_VER%..."
    )
)

call :Info "Installing Node.js %NODE_MSI_VER%..."

if "%IS_ADMIN%"=="1" goto :NodeMSI

:: ---- Non-admin: Portable ZIP ----
:NodePortable
set "NODE_ZIP_URL=%BEST_NODE_MIRROR%v%NODE_MSI_VER%/node-v%NODE_MSI_VER%-win-x64.zip"
set "NODE_ZIP=%TEMP%\node-v%NODE_MSI_VER%-win-x64.zip"
set "NODE_PORTABLE=%LOCALAPPDATA%\Programs\nodejs"

call :Info "Using portable Node.js (no admin required)"
call :Info "Downloading Node.js %NODE_MSI_VER%..."
curl -L -# -o "%NODE_ZIP%" "%NODE_ZIP_URL%" 2>> "%LOG%"
if errorlevel 1 (
    bitsadmin /transfer node_dl /download /priority FOREGROUND "%NODE_ZIP_URL%" "%NODE_ZIP%" >> "%LOG%" 2>&1
    if errorlevel 1 (
        call :Err "Download failed"
        exit /b 1
    )
)

for %%A in ("%NODE_ZIP%") do set "FSIZE=%%~zA"
if !FSIZE! LSS 5000000 (
    call :Err "ZIP too small (!FSIZE! bytes)"
    del "%NODE_ZIP%" >nul 2>&1
    exit /b 1
)
call :Ok "Downloaded !FSIZE! bytes"

call :Info "Extracting to %NODE_PORTABLE%..."
if not exist "%NODE_PORTABLE%" mkdir "%NODE_PORTABLE%" >nul 2>&1
tar -xf "%NODE_ZIP%" -C "%TEMP%" >> "%LOG%" 2>&1
for /d %%D in ("%TEMP%\node-v%NODE_MSI_VER%-win-x64") do (
    xcopy /e /y /q "%%D\*" "%NODE_PORTABLE%\" >nul 2>&1
    rmdir /s /q "%%D" >nul 2>&1
)
del "%NODE_ZIP%" >nul 2>&1

:: Add to PATH - put NEW path at FRONT so it overrides older system Node
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USR_PATH=%%b"
if not defined USR_PATH set "USR_PATH="
setx PATH "%NODE_PORTABLE%;!USR_PATH!" >nul 2>&1
call :Ok "Added %NODE_PORTABLE% to user PATH (front)"
set "PATH=%NODE_PORTABLE%;%PATH%"
call :Ok "Portable Node.js installed"
goto :NodeDone

:: ---- Admin: MSI Installer ----
:NodeMSI
set "NODE_URL=%BEST_NODE_MIRROR%v%NODE_MSI_VER%/node-v%NODE_MSI_VER%-x64.msi"
set "NODE_MSI=%TEMP%\node-v%NODE_MSI_VER%-x64.msi"

call :Info "Downloading Node.js %NODE_MSI_VER%..."
curl -L -# -o "%NODE_MSI%" "%NODE_URL%" 2>> "%LOG%"
if errorlevel 1 (
    bitsadmin /transfer node_dl /download /priority FOREGROUND "%NODE_URL%" "%NODE_MSI%" >> "%LOG%" 2>&1
    if errorlevel 1 (
        call :Err "Download failed"
        exit /b 1
    )
)

for %%A in ("%NODE_MSI%") do set "FSIZE=%%~zA"
if !FSIZE! LSS 1000000 (
    call :Err "MSI too small (!FSIZE! bytes)"
    del "%NODE_MSI%" >nul 2>&1
    exit /b 1
)
call :Ok "Downloaded !FSIZE! bytes"

set "MSI_LOG=%TEMP%\node-msi-install.log"
call :Info "Installing Node.js (progress window will appear)..."
msiexec /i "%NODE_MSI%" /passive /norestart /l*v "%MSI_LOG%"
if errorlevel 1 (
    call :Err "MSI install failed (code: !ERRORLEVEL!)"
    del "%NODE_MSI%" >nul 2>&1
    exit /b 1
)
del "%NODE_MSI%" >nul 2>&1
call :Ok "Node.js installed"

:NodeDone
:: Put new Node paths at FRONT of PATH so they override any older system installation
set "PATH=%LOCALAPPDATA%\Programs\nodejs;C:\Program Files\nodejs;%PATH%;%NPM_PREFIX%"
timeout /t 2 /nobreak >nul
:: Use absolute path first, then fall back to where result
if exist "%LOCALAPPDATA%\Programs\nodejs\node.exe" (
    for /f "tokens=*" %%v in ('"%LOCALAPPDATA%\Programs\nodejs\node.exe" -v 2^>nul') do set "NODE_VER=%%v"
) else (
    for /f "tokens=*" %%v in ('node -v 2^>nul') do set "NODE_VER=%%v"
)
call :Ok "Node.js ready: !NODE_VER!"

:: ---- Install pnpm ----
:InstallPnpm
echo.
call :Info "Step 2.3: Checking pnpm..."
where pnpm >nul 2>nul
if not errorlevel 1 (
    call :Ok "pnpm already installed"
    goto :Done
)

call :Info "Installing pnpm..."
call npm install -g pnpm --registry %BEST_NPM_MIRROR%
if errorlevel 1 (
    call :Warn "pnpm install failed - will use npm for OpenClaw"
    goto :Done
)
call :Ok "pnpm installed"

call :Info "Configuring pnpm environment (pnpm setup)..."
call pnpm setup >> "%LOG%" 2>&1
if not errorlevel 1 (
    for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PNPM_HOME 2^>nul') do set "PNPM_HOME=%%b"
    if defined PNPM_HOME (
        set "PATH=%PNPM_HOME%;%PATH%"
        call :Ok "pnpm setup complete - PNPM_HOME: !PNPM_HOME!"
    )
)

:Done
echo.
call :Ok "Stage 2 complete - all base tools installed"
exit /b 0

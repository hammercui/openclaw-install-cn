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
if not defined SCRIPT_DIR set "SCRIPT_DIR=%~dp0"

set "NODE_TARGET=22"
set "NODE_MSI_VER=22.22.1"
set "NODE_CACHE_DIR=%TEMP%\openclaw-cache"
set "PNPM_DEFAULT_HOME=%LOCALAPPDATA%\pnpm"
set "PNPM_DEFAULT_STORE=%LOCALAPPDATA%\pnpm-store"

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

:ReadNodeConfig
set "CONFIG_FILE=%SCRIPT_DIR%openclaw-install.json"
if defined OPENCLAW_CONFIG_FILE set "CONFIG_FILE=%OPENCLAW_CONFIG_FILE%"
if not exist "%CONFIG_FILE%" goto :ParseNodeTarget

set "IN_NODEJS=0"
for /f "usebackq delims=" %%L in ("%CONFIG_FILE%") do (
    set "LINE=%%L"
    set "LINE_TRIM=!LINE: =!"
    set "LINE_KEY=!LINE_TRIM:"=!"

    if /i "!LINE_KEY!"=="nodejs:{" set "IN_NODEJS=1"

    if "!IN_NODEJS!"=="1" (
        echo(!LINE_KEY!| findstr /i /c:"targetMajor:" >nul && call :ExtractJsonValue "!LINE!" NODE_TARGET
        echo(!LINE_KEY!| findstr /i /c:"targetVersion:" >nul && call :ExtractJsonValue "!LINE!" NODE_MSI_VER
        if /i "!LINE_KEY!"=="}," set "IN_NODEJS=0"
        if /i "!LINE_KEY!"=="}" set "IN_NODEJS=0"
    )
)

:ParseNodeTarget
for /f "tokens=1-3 delims=." %%a in ("%NODE_MSI_VER%") do (
    set "NODE_REQ_MAJOR=%%a"
    set "NODE_REQ_MINOR=%%b"
    set "NODE_REQ_PATCH=%%c"
)
if not defined NODE_TARGET set "NODE_TARGET=%NODE_REQ_MAJOR%"
if not defined NODE_REQ_MAJOR set "NODE_REQ_MAJOR=%NODE_TARGET%"
if not defined NODE_REQ_MINOR set "NODE_REQ_MINOR=0"
if not defined NODE_REQ_PATCH set "NODE_REQ_PATCH=0"
goto :eof

:ExtractJsonValue
set "_line=%~1"
set "_value=%_line:*:=%"
for /f "tokens=* delims= " %%a in ("%_value%") do set "_value=%%a"
set "_value=!_value:"=!"
if "!_value:~-1!"=="," set "_value=!_value:~0,-1!"
set "%~2=!_value!"
goto :eof

:EnsureNodeCache
set "CACHE_FILE=%~1"
set "CACHE_URL=%~2"
set "CACHE_MIN_SIZE=%~3"
set "CACHE_LABEL=%~4"
set "CACHE_SIZE=0"

if not exist "%NODE_CACHE_DIR%" mkdir "%NODE_CACHE_DIR%" >nul 2>&1

if exist "%CACHE_FILE%" (
    for %%A in ("%CACHE_FILE%") do set "CACHE_SIZE=%%~zA"
    if !CACHE_SIZE! GEQ %CACHE_MIN_SIZE% (
        call :Ok "Using cached %CACHE_LABEL%: !CACHE_SIZE! bytes"
        goto :eof
    )
    call :Warn "Cached %CACHE_LABEL% is incomplete (!CACHE_SIZE! bytes) - re-downloading"
    del "%CACHE_FILE%" >nul 2>&1
)

call :Info "Downloading %CACHE_LABEL%..."
curl -L -# -o "%CACHE_FILE%" "%CACHE_URL%" 2>> "%LOG%"
if errorlevel 1 (
    bitsadmin /transfer node_dl /download /priority FOREGROUND "%CACHE_URL%" "%CACHE_FILE%" >> "%LOG%" 2>&1
    if errorlevel 1 (
        call :Err "Download failed"
        exit /b 1
    )
)

for %%A in ("%CACHE_FILE%") do set "CACHE_SIZE=%%~zA"
if !CACHE_SIZE! LSS %CACHE_MIN_SIZE% (
    call :Err "%CACHE_LABEL% too small (!CACHE_SIZE! bytes)"
    del "%CACHE_FILE%" >nul 2>&1
    exit /b 1
)
call :Ok "Downloaded !CACHE_SIZE! bytes"
goto :eof

:EnsureUserPathContains
set "PATH_TO_ADD=%~1"
set "USR_PATH="
set "PATH_CHECK_FILE=%TEMP%\openclaw-pathcheck-%RANDOM%.tmp"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USR_PATH=%%b"
if not defined USR_PATH set "USR_PATH="
> "!PATH_CHECK_FILE!" echo(!USR_PATH!
findstr /i /c:"%~1" "!PATH_CHECK_FILE!" >nul 2>&1
del "!PATH_CHECK_FILE!" >nul 2>&1
if errorlevel 1 (
    setx PATH "%~1;!USR_PATH!" >nul 2>&1
    call :Ok "Added %~1 to user PATH"
) else (
    call :Info "PATH already contains %~1"
)
set "PATH=%~1;%PATH%"
goto :eof

:EnsureUserPathFirst
set "PATH_TO_ADD=%~1"
set "USR_PATH="
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USR_PATH=%%b"
if not defined USR_PATH set "USR_PATH="

set "USR_PATH_CLEAN=!USR_PATH;%~1;=;!"
set "USR_PATH_CLEAN=!USR_PATH_CLEAN:%~1;=!"
set "USR_PATH_CLEAN=!USR_PATH_CLEAN:;%~1=!"
set "USR_PATH_CLEAN=!USR_PATH_CLEAN:%~1=!"
set "USR_PATH_CLEAN=!USR_PATH_CLEAN:;;=;!"

if defined USR_PATH_CLEAN (
    setx PATH "%~1;!USR_PATH_CLEAN!" >nul 2>&1
) else (
    setx PATH "%~1" >nul 2>&1
)
set "PATH=%~1;%PATH%"
call :Ok "Pinned %~1 to the front of user PATH"
goto :eof

:EnsurePnpmReady
call :Info "Ensuring pnpm global environment..."
set "PNPM_HOME=%PNPM_DEFAULT_HOME%"
set "PNPM_STORE=%PNPM_DEFAULT_STORE%"

for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PNPM_HOME 2^>nul') do set "PNPM_HOME=%%b"
if not defined PNPM_HOME set "PNPM_HOME=%PNPM_DEFAULT_HOME%"

if not exist "!PNPM_HOME!" mkdir "!PNPM_HOME!" >nul 2>&1
if not exist "!PNPM_STORE!" mkdir "!PNPM_STORE!" >nul 2>&1

set "PNPM_HOME=!PNPM_HOME!"
setx PNPM_HOME "!PNPM_HOME!" >nul 2>&1
call :EnsureUserPathContains "!PNPM_HOME!"

call pnpm config set global-bin-dir "!PNPM_HOME!" >> "%LOG%" 2>&1
call pnpm config set store-dir "!PNPM_STORE!" >> "%LOG%" 2>&1
call pnpm bin -g >nul 2>&1
if errorlevel 1 (
    call :Warn "pnpm global environment still not ready - Stage 3 may fallback to npm"
    goto :eof
)
call :Ok "pnpm global environment ready: !PNPM_HOME!"
goto :eof

:: ============================================================
::  Main Flow
:: ============================================================
:Main
call :ReadNodeConfig
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
    
    :: Check if version >= configured target major/minor
    set "VERSION_OK=0"
    if !NODE_MAJOR! GTR !NODE_REQ_MAJOR! set "VERSION_OK=1"
    if !NODE_MAJOR! EQU !NODE_REQ_MAJOR! if !NODE_MINOR! GEQ !NODE_REQ_MINOR! set "VERSION_OK=1"

    if "!VERSION_OK!"=="1" (
        call :Ok "Version check passed (requires v%NODE_MSI_VER%+)"
        goto :InstallPnpm
    ) else (
        call :Warn "Node.js !NODE_VER! is too old (requires v%NODE_MSI_VER%+)"
        call :Info "Will upgrade to Node.js %NODE_MSI_VER%..."
    )
)

call :Info "Installing Node.js %NODE_MSI_VER%..."

if "%IS_ADMIN%"=="1" goto :NodeMSI

:: ---- Non-admin: Portable ZIP ----
:NodePortable
set "NODE_ZIP_URL=%BEST_NODE_MIRROR%v%NODE_MSI_VER%/node-v%NODE_MSI_VER%-win-x64.zip"
set "NODE_ZIP=%NODE_CACHE_DIR%\node-v%NODE_MSI_VER%-win-x64.zip"
set "NODE_PORTABLE=%LOCALAPPDATA%\Programs\nodejs"

call :Info "Using portable Node.js (no admin required)"
call :EnsureNodeCache "%NODE_ZIP%" "%NODE_ZIP_URL%" "5000000" "Node.js ZIP %NODE_MSI_VER%"

call :Info "Extracting to %NODE_PORTABLE%..."
if not exist "%NODE_PORTABLE%" mkdir "%NODE_PORTABLE%" >nul 2>&1
tar -xf "%NODE_ZIP%" -C "%TEMP%" >> "%LOG%" 2>&1
for /d %%D in ("%TEMP%\node-v%NODE_MSI_VER%-win-x64") do (
    xcopy /e /y /q "%%D\*" "%NODE_PORTABLE%\" >nul 2>&1
    rmdir /s /q "%%D" >nul 2>&1
)

:: Add to PATH - put NEW path at FRONT so it overrides older system Node
call :EnsureUserPathFirst "%NODE_PORTABLE%"
call :Ok "Portable Node.js installed"
goto :NodeDone

:: ---- Admin: MSI Installer ----
:NodeMSI
set "NODE_URL=%BEST_NODE_MIRROR%v%NODE_MSI_VER%/node-v%NODE_MSI_VER%-x64.msi"
set "NODE_MSI=%NODE_CACHE_DIR%\node-v%NODE_MSI_VER%-x64.msi"

call :EnsureNodeCache "%NODE_MSI%" "%NODE_URL%" "1000000" "Node.js MSI %NODE_MSI_VER%"

set "MSI_LOG=%TEMP%\node-msi-install.log"
call :Info "Installing Node.js (progress window will appear)..."
msiexec /i "%NODE_MSI%" /passive /norestart /l*v "%MSI_LOG%"
if errorlevel 1 (
    call :Err "MSI install failed (code: !ERRORLEVEL!)"
    exit /b 1
)
call :EnsureUserPathFirst "C:\Program Files\nodejs"
call :Ok "Node.js installed"

:NodeDone
:: Put new Node paths at FRONT of PATH so they override any older system installation
set "PATH=%LOCALAPPDATA%\Programs\nodejs;C:\Program Files\nodejs;%PATH%;%NPM_PREFIX%"
ping -n 3 127.0.0.1 >nul
:: Use absolute path first, then fall back to where result
if exist "%LOCALAPPDATA%\Programs\nodejs\node.exe" (
    for /f "tokens=*" %%v in ('"%LOCALAPPDATA%\Programs\nodejs\node.exe" -v 2^>nul') do set "NODE_VER=%%v"
) else if exist "C:\Program Files\nodejs\node.exe" (
    for /f "tokens=*" %%v in ('"C:\Program Files\nodejs\node.exe" -v 2^>nul') do set "NODE_VER=%%v"
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
    call :Info "Checking pnpm global environment..."
    call :EnsurePnpmReady
    goto :Done
)

call :Info "Installing pnpm..."
call npm install -g pnpm --registry %BEST_NPM_MIRROR%
if errorlevel 1 (
    call :Warn "pnpm install failed - will use npm for OpenClaw"
    goto :Done
)
call :Ok "pnpm installed"

call :EnsurePnpmReady

:Done
echo.
call :Ok "Stage 2 complete - all base tools installed"
exit /b 0

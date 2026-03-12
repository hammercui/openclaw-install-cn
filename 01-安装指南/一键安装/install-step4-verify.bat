@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  Stage 4: Verify Installation + Auto-start Configuration
:: ============================================================

if not defined LOG set "LOG=%TEMP%\openclaw-install.log"
if not defined NPM_PREFIX set "NPM_PREFIX=%APPDATA%\npm"
if not defined BEST_NPM_MIRROR set "BEST_NPM_MIRROR=https://registry.npmmirror.com"
if not defined BEST_NPM_NAME set "BEST_NPM_NAME=Taobao"

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
call :Info "Stage 4: Verification and configuration"
echo.

call :Info "Step 4.1: Verifying OpenClaw installation..."

:: ---- Rebuild PATH from all known sources ----
:: Each step file runs setlocal/endlocal, so PATH changes are lost.
:: Reconstruct from registry + known locations.

:: 1. npm global prefix
for /f "tokens=*" %%p in ('npm config get prefix 2^>nul') do set "NPM_PREFIX=%%p"
call :Info "npm prefix  : !NPM_PREFIX!"

:: 2. pnpm global bin
set "PNPM_BIN="
where pnpm >nul 2>nul
if not errorlevel 1 (
    for /f "tokens=*" %%p in ('pnpm bin -g 2^>nul') do set "PNPM_BIN=%%p"
)
if defined PNPM_BIN call :Info "pnpm bin    : !PNPM_BIN!"

:: 3. PNPM_HOME from registry
set "PNPM_HOME="
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PNPM_HOME 2^>nul') do set "PNPM_HOME=%%b"
if defined PNPM_HOME call :Info "PNPM_HOME   : !PNPM_HOME!"

:: 4. User PATH from registry (permanent, survives setlocal/endlocal)
set "REG_USER_PATH="
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "REG_USER_PATH=%%b"

:: 5. Rebuild PATH
set "PATH=!PATH!;!REG_USER_PATH!"
set "PATH=!PATH!;!NPM_PREFIX!"
set "PATH=!PATH!;!APPDATA!\npm"
set "PATH=!PATH!;C:\Program Files\nodejs;!LOCALAPPDATA!\Programs\nodejs"
if defined PNPM_BIN set "PATH=!PATH!;!PNPM_BIN!"
if defined PNPM_HOME set "PATH=!PATH!;!PNPM_HOME!"

:: ---- Try to find openclaw ----
set "OC_FOUND=0"
where openclaw >nul 2>nul
if not errorlevel 1 set "OC_FOUND=1"

:: If not found via where, scan known locations directly
if "!OC_FOUND!"=="0" (
    call :Warn "openclaw not in PATH - scanning known locations..."
    echo.
    echo [ INFO ] Checking: !NPM_PREFIX!\openclaw.cmd
    if exist "!NPM_PREFIX!\openclaw.cmd" (
        set "PATH=!NPM_PREFIX!;!PATH!"
        set "OC_FOUND=1"
        echo [  OK  ] Found openclaw.cmd
    )
)

if "!OC_FOUND!"=="0" (
    echo [ INFO ] Checking: !APPDATA!\npm\openclaw.cmd
    if exist "!APPDATA!\npm\openclaw.cmd" (
        set "PATH=!APPDATA!\npm;!PATH!"
        set "OC_FOUND=1"
        echo [  OK  ] Found openclaw.cmd
    )
)

if "!OC_FOUND!"=="0" if defined PNPM_BIN (
    echo [ INFO ] Checking: !PNPM_BIN!\openclaw.cmd
    if exist "!PNPM_BIN!\openclaw.cmd" (
        set "PATH=!PNPM_BIN!;!PATH!"
        set "OC_FOUND=1"
        echo [  OK  ] Found openclaw.cmd
    )
)

if "!OC_FOUND!"=="0" if defined PNPM_HOME (
    echo [ INFO ] Checking: !PNPM_HOME!\openclaw.cmd
    if exist "!PNPM_HOME!\openclaw.cmd" (
        set "PATH=!PNPM_HOME!;!PATH!"
        set "OC_FOUND=1"
        echo [  OK  ] Found openclaw.cmd
    )
)

:: ---- Final verification ----
if "!OC_FOUND!"=="0" goto :NotFound

where openclaw >nul 2>nul
if errorlevel 1 goto :NotFound

:: Print version
for /f "tokens=*" %%v in ('openclaw --version 2^>nul') do set "OC_VERSION=%%v"
for /f "tokens=*" %%v in ('node -v 2^>nul') do set "NODE_VER=%%v"
call :Ok "OpenClaw !OC_VERSION! verified"
call :Ok "Node.js !NODE_VER!"
goto :AutoStart

:: ---- Not found - diagnostic ----
:NotFound
call :Err "openclaw command not found"
echo.
echo  Scanned locations:
echo    npm prefix  : !NPM_PREFIX!
echo    APPDATA npm : !APPDATA!\npm
echo    pnpm bin    : !PNPM_BIN!
echo    PNPM_HOME   : !PNPM_HOME!
echo.
echo  --- File search in npm prefix ---
dir "!NPM_PREFIX!\openclaw*" 2>nul
if errorlevel 1 echo    (no openclaw files found)
echo.
echo  --- Checking node_modules ---
if exist "!NPM_PREFIX!\node_modules\openclaw\package.json" (
    echo    Package exists at: !NPM_PREFIX!\node_modules\openclaw
    findstr /i "bin" "!NPM_PREFIX!\node_modules\openclaw\package.json" 2>nul
) else (
    echo    Package NOT found in node_modules
)
echo.
echo  SOLUTION:
echo    npm uninstall -g openclaw 2>nul
echo    npm install -g openclaw@latest --registry !BEST_NPM_MIRROR! --loglevel http
echo    (then restart CMD to refresh PATH)
echo.
exit /b 1

:: ---- Configure auto-start ----
:AutoStart
echo.
call :Info "Step 4.2: Auto-start configuration (optional)"

set /p "DO_AUTOSTART=Configure OpenClaw Gateway to auto-start at login? [Y/N]: "
if /i not "!DO_AUTOSTART!"=="Y" (
    call :Info "Skipping auto-start"
    goto :Summary
)

call :Info "Adding to registry startup entries..."
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" ^
    /v "OpenClawGateway" /t REG_SZ ^
    /d "openclaw gateway start" /f >nul 2>&1

if not errorlevel 1 (
    call :Ok "Auto-start configured via registry"
    call :Info "  Key: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    call :Info "  Remove with: reg delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v OpenClawGateway /f"
) else (
    call :Warn "Registry failed - using Startup folder..."
    set "STARTUP_DIR=!APPDATA!\Microsoft\Windows\Start Menu\Programs\Startup"
    set "AUTORUN_FILE=!STARTUP_DIR!\OpenClawGateway.bat"
    > "!AUTORUN_FILE!" echo @echo off
    >> "!AUTORUN_FILE!" echo start /min "" openclaw gateway start
    call :Ok "Startup script created: !AUTORUN_FILE!"
)

:: ---- Summary ----
:Summary
echo.
echo ============================================================
echo   Installation Summary
echo ============================================================
echo.
echo   OpenClaw    : !OC_VERSION!
echo   Node.js     : !NODE_VER!
echo   npm mirror  : !BEST_NPM_NAME! (!BEST_NPM_MIRROR!)
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
call :Ok "Stage 4 complete"
exit /b 0

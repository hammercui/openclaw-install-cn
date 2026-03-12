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

:: ---- Verify openclaw command ----
call :Info "Step 4.1: Verifying OpenClaw installation..."

:: Refresh PATH with all possible locations
for /f "tokens=*" %%p in ('npm config get prefix 2^>nul') do set "NPM_PREFIX=%%p"
for /f "tokens=*" %%p in ('pnpm bin -g 2^>nul') do set "PNPM_BIN=%%p"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PNPM_HOME 2^>nul') do set "PNPM_HOME=%%b"

set "PATH=%PATH%;%NPM_PREFIX%"
if defined PNPM_BIN set "PATH=%PATH%;%PNPM_BIN%"
if defined PNPM_HOME set "PATH=%PATH%;%PNPM_HOME%"
set "PATH=%PATH%;C:\Program Files\nodejs;%LOCALAPPDATA%\Programs\nodejs"

where openclaw >nul 2>nul
if errorlevel 1 (
    call :Err "openclaw command not found - running diagnostic..."
    echo.
    echo  npm prefix: %NPM_PREFIX%
    echo  pnpm bin  : %PNPM_BIN%
    echo  PNPM_HOME : %PNPM_HOME%
    echo.
    echo  --- Checking node_modules ---
    if exist "%NPM_PREFIX%\node_modules\openclaw" (
        echo  Package dir: %NPM_PREFIX%\node_modules\openclaw
        if exist "%NPM_PREFIX%\node_modules\openclaw\bin" (
            echo  bin/ directory EXISTS
            dir "%NPM_PREFIX%\node_modules\openclaw\bin\*" 2>nul
        ) else (
            echo  bin/ directory MISSING
        )
        findstr /i "bin" "%NPM_PREFIX%\node_modules\openclaw\package.json" 2>nul
    ) else (
        echo  Package NOT installed
    )
    echo.
    echo  SOLUTION:
    echo    npm uninstall -g openclaw
    echo    npm install -g openclaw@latest --registry %BEST_NPM_MIRROR%
    echo    (then restart CMD to refresh PATH)
    echo.
    exit /b 1
)

:: Print version
for /f "tokens=*" %%v in ('openclaw --version 2^>nul') do set "OC_VERSION=%%v"
for /f "tokens=*" %%v in ('node -v 2^>nul') do set "NODE_VER=%%v"
call :Ok "OpenClaw %OC_VERSION% verified"
call :Ok "Node.js %NODE_VER%"

:: ---- Configure auto-start ----
echo.
call :Info "Step 4.2: Auto-start configuration (optional)"

set /p "DO_AUTOSTART=Configure OpenClaw Gateway to auto-start at login? [Y/N]: "
if /i not "%DO_AUTOSTART%"=="Y" (
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
    set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
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
echo   OpenClaw    : %OC_VERSION%
echo   Node.js     : %NODE_VER%
echo   npm mirror  : %BEST_NPM_NAME% (%BEST_NPM_MIRROR%)
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
>> "%LOG%" echo OpenClaw: %OC_VERSION%

set /p "DO_INIT=Initialize OpenClaw now? [Y/N]: "
if /i "%DO_INIT%"=="Y" (
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

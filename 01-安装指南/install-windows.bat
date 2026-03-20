@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  OpenClaw One-Click Installer for Windows (Main Entry)
::  Version: 3.2.0 - Modular Architecture
::  Pure CMD - no PowerShell dependency, no admin required
:: ============================================================

chcp 437 >nul 2>nul

:: ============================================================
::  Configuration
:: ============================================================
set "VERSION=3.2.0"
set "LOG=%TEMP%\openclaw-install.log"
set "SCRIPT_DIR=%~dp0"
set "OPENCLAW_CONFIG_FILE=%SCRIPT_DIR%openclaw-install.json"

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
echo    - Test all mirrors and choose the best available one
echo    - Install Git, Node.js, pnpm
echo    - Install OpenClaw CLI
echo    - Configure auto-start
echo.
echo  Log file: %LOG%
echo ============================================================
echo.

:: ============================================================
::  Check Admin Rights (informational only, not required)
:: ============================================================
net session >nul 2>&1
if errorlevel 1 (
    set "IS_ADMIN=0"
    echo [ INFO ] Running as standard user (no admin required)
) else (
    set "IS_ADMIN=1"
    echo [ INFO ] Running as Administrator
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
    exit /b 1
)

:: ============================================================
::  Refresh PATH before Stage 4
::  Each step runs setlocal/endlocal which reverts PATH changes.
::  setx writes to registry but doesn't update current session.
::  Manually rebuild PATH so step4 can find openclaw.
:: ============================================================
echo.
echo [ INFO ] Refreshing PATH for verification...

:: Read user PATH from registry (includes setx additions from step1/step2)
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "REG_USR_PATH=%%b"
if defined REG_USR_PATH set "PATH=!REG_USR_PATH!;!PATH!"

:: Add all known npm/pnpm/node locations
set "PATH=!PATH!;!APPDATA!\npm"
set "PATH=!PATH!;C:\Program Files\nodejs;!LOCALAPPDATA!\Programs\nodejs"
set "PATH=!PATH!;C:\Program Files\Git\cmd;!LOCALAPPDATA!\Programs\Git\cmd"

:: Add PNPM_HOME if set in registry
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PNPM_HOME 2^>nul') do (
    set "PATH=!PATH!;%%b"
)

:: Quick sanity check
where openclaw >nul 2>nul
if not errorlevel 1 (
    echo [  OK  ] openclaw found in PATH
) else (
    echo [ WARN ] openclaw not yet in PATH - step4 will attempt detailed scan
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
endlocal & (
    set "PATH=%PATH%"
)
exit /b 0

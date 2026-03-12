@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  Stage 3: Install OpenClaw
::  Strategy: npm first (with progress), pnpm as fallback
:: ============================================================

if not defined LOG set "LOG=%TEMP%\openclaw-install.log"
if not defined BEST_NPM_MIRROR set "BEST_NPM_MIRROR=https://registry.npmmirror.com"

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
call :Info "Stage 3: Installing OpenClaw"
echo.

call :Info "Registry: !BEST_NPM_MIRROR!"

:: ---- Check if already installed ----
where openclaw >nul 2>nul
if not errorlevel 1 (
    call :Info "OpenClaw already installed - updating..."
    echo.

    :: Detect which package manager installed it
    set "UPDATE_PM=npm"
    npm list -g openclaw >nul 2>nul
    if not errorlevel 1 (
        set "UPDATE_PM=npm"
    ) else (
        where pnpm >nul 2>nul
        if not errorlevel 1 (
            pnpm list -g openclaw >nul 2>nul
            if not errorlevel 1 set "UPDATE_PM=pnpm"
        )
    )

    echo ============================================================
    echo   Updating OpenClaw via !UPDATE_PM! (progress shown below)
    echo ============================================================
    echo.
    if "!UPDATE_PM!"=="npm" (
        npm update -g openclaw --registry !BEST_NPM_MIRROR! --loglevel http 2>&1
    ) else (
        pnpm update -g openclaw --reporter=default 2>&1
    )
    echo.
    goto :Done
)

:: ---- Fresh install: npm first ----
echo.
echo ============================================================
echo   Installing OpenClaw via npm - this may take 1-3 minutes
echo   Progress will be displayed below:
echo ============================================================
echo.
npm install -g openclaw@latest --registry !BEST_NPM_MIRROR! --loglevel http 2>&1
if not errorlevel 1 (
    echo.
    call :Ok "OpenClaw installed via npm"
    goto :Done
)
echo.
call :Warn "npm install failed - trying pnpm as fallback..."

:: ---- Fallback: pnpm ----
where pnpm >nul 2>nul
if errorlevel 1 (
    call :Err "pnpm not available either - installation failed"
    echo.
    echo  Troubleshooting:
    echo    1. Check git: where git
    echo    2. Test registry: curl !BEST_NPM_MIRROR!
    echo    3. Full log: %LOG%
    echo.
    echo  Manual install:
    echo    npm install -g openclaw@latest --registry !BEST_NPM_MIRROR! --verbose
    echo.
    exit /b 1
)

echo.
echo ============================================================
echo   Installing OpenClaw via pnpm (fallback) - please wait
echo ============================================================
echo.
pnpm install -g openclaw@latest --force --reporter=default 2>&1
if errorlevel 1 (
    echo.
    call :Err "OpenClaw installation failed via both npm and pnpm"
    echo.
    echo  Troubleshooting:
    echo    1. Check git: where git
    echo    2. Test registry: curl !BEST_NPM_MIRROR!
    echo    3. Full log: %LOG%
    echo.
    exit /b 1
)
echo.
call :Ok "OpenClaw installed via pnpm"

:Done
echo.
call :Ok "Stage 3 complete - OpenClaw installed"
exit /b 0

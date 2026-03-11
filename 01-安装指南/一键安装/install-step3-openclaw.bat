@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  Stage 3: Install OpenClaw
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

call :Info "Registry: %BEST_NPM_MIRROR%"

:: Check if already installed
where openclaw >nul 2>nul
if not errorlevel 1 (
    call :Info "OpenClaw already installed - updating..."
    where pnpm >nul 2>nul
    if not errorlevel 1 (
        pnpm update -g openclaw
    ) else (
        npm update -g openclaw --registry %BEST_NPM_MIRROR%
    )
    goto :Done
)

:: ---- Try pnpm first (better for packages with git deps) ----
where pnpm >nul 2>nul
if not errorlevel 1 (
    call :Info "Using pnpm for installation (more reliable for binary deps)"
    call :Info "Running: pnpm install -g openclaw@latest --force"
    pnpm install -g openclaw@latest --force
    if not errorlevel 1 (
        call :Ok "OpenClaw installed via pnpm"
        goto :Done
    )
    call :Warn "pnpm install failed - falling back to npm"
)

:: ---- Fallback to npm ----
call :Info "Running: npm install -g openclaw@latest"
npm install -g openclaw@latest --registry %BEST_NPM_MIRROR%
if errorlevel 1 (
    call :Err "OpenClaw installation failed"
    echo.
    echo  Troubleshooting:
    echo    1. Check git: where git
    echo    2. Test registry: curl %BEST_NPM_MIRROR%
    echo    3. Full log: %LOG%
    echo.
    echo  Manual install:
    echo    npm install -g openclaw@latest --registry %BEST_NPM_MIRROR% --verbose
    echo.
    exit /b 1
)
call :Ok "OpenClaw installed via npm"

:Done
echo.
call :Ok "Stage 3 complete - OpenClaw installed"
exit /b 0

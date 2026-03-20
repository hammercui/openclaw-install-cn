@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  Stage 3: Install OpenClaw
::  Strategy: Read config, prefer pnpm, fallback to npm
:: ============================================================

if not defined LOG set "LOG=%TEMP%\openclaw-install.log"
if not defined SCRIPT_DIR set "SCRIPT_DIR=%~dp0"

:: Read OpenClaw install config
if defined OPENCLAW_CONFIG_FILE (
    set "CONFIG_FILE=%OPENCLAW_CONFIG_FILE%"
) else (
    set "CONFIG_FILE=%SCRIPT_DIR%openclaw-install.json"
)
set "OPENCLAW_VERSION=latest"
set "OPENCLAW_PACKAGE=openclaw"
set "OPENCLAW_CONFIG_REGISTRY=https://registry.npmmirror.com"
set "WIN_INSTALL_CMD=npm install -g {package}@{version} --registry {registry}"
set "WIN_UPDATE_CMD=npm install -g {package}@{version} --registry {registry} --force"
set "WIN_PNPM_CMD=pnpm install -g {package}@{version} --force"
set "PNPM_READY=0"

call :DetectNpmMirror
call :ReadConfig
call :DetectPnpm

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

:ReadConfig
if not exist "%CONFIG_FILE%" (
    call :Warn "Config not found, using defaults: %CONFIG_FILE%"
    call :RenderTemplate "%WIN_INSTALL_CMD%" RENDERED_INSTALL_CMD
    call :RenderTemplate "%WIN_UPDATE_CMD%" RENDERED_UPDATE_CMD
    call :RenderTemplate "%WIN_PNPM_CMD%" RENDERED_PNPM_CMD
    goto :eof
)

set "IN_OPENCLAW=0"
set "IN_WINDOWS=0"
for /f "usebackq delims=" %%L in ("%CONFIG_FILE%") do (
    set "LINE=%%L"
    set "LINE_NOSPACE=!LINE: =!"

    if /i "!LINE_NOSPACE!"=="\"openclaw\":{" set "IN_OPENCLAW=1" & set "IN_WINDOWS=0"
    if /i "!LINE_NOSPACE!"=="\"windows\":{" set "IN_WINDOWS=1" & set "IN_OPENCLAW=0"

    if "!IN_OPENCLAW!"=="1" (
        echo(!LINE_NOSPACE!| findstr /i /c:"\"version\":" >nul && call :ExtractValue "!LINE!" OPENCLAW_VERSION
        echo(!LINE_NOSPACE!| findstr /i /c:"\"package\":" >nul && call :ExtractValue "!LINE!" OPENCLAW_PACKAGE
        echo(!LINE_NOSPACE!| findstr /i /c:"\"registry\":" >nul && call :ExtractValue "!LINE!" OPENCLAW_CONFIG_REGISTRY
    )

    if "!IN_WINDOWS!"=="1" (
        echo(!LINE_NOSPACE!| findstr /i /c:"\"installCommand\":" >nul && call :ExtractValue "!LINE!" WIN_INSTALL_CMD
        echo(!LINE_NOSPACE!| findstr /i /c:"\"updateCommand\":" >nul && call :ExtractValue "!LINE!" WIN_UPDATE_CMD
        echo(!LINE_NOSPACE!| findstr /i /c:"\"pnpmCommand\":" >nul && call :ExtractValue "!LINE!" WIN_PNPM_CMD
    )

    if "!IN_OPENCLAW!!IN_WINDOWS!"=="10" (
        if /i "!LINE_NOSPACE!"=="}," set "IN_OPENCLAW=0"
        if /i "!LINE_NOSPACE!"=="}" set "IN_OPENCLAW=0"
    )
    if "!IN_OPENCLAW!!IN_WINDOWS!"=="01" (
        if /i "!LINE_NOSPACE!"=="}," set "IN_WINDOWS=0"
        if /i "!LINE_NOSPACE!"=="}" set "IN_WINDOWS=0"
    )
)

if not defined OPENCLAW_VERSION set "OPENCLAW_VERSION=latest"
if not defined OPENCLAW_PACKAGE set "OPENCLAW_PACKAGE=openclaw"
if not defined OPENCLAW_CONFIG_REGISTRY set "OPENCLAW_CONFIG_REGISTRY=https://registry.npmmirror.com"

if defined BEST_NPM_MIRROR (
    set "OPENCLAW_REGISTRY=!BEST_NPM_MIRROR!"
) else (
    set "OPENCLAW_REGISTRY=!OPENCLAW_CONFIG_REGISTRY!"
)

call :RenderTemplate "!WIN_INSTALL_CMD!" RENDERED_INSTALL_CMD
call :RenderTemplate "!WIN_UPDATE_CMD!" RENDERED_UPDATE_CMD
call :RenderTemplate "!WIN_PNPM_CMD!" RENDERED_PNPM_CMD
goto :eof

:ExtractValue
set "_line=%~1"
set "_value=%_line:*:=%"
for /f "tokens=* delims= " %%a in ("%_value%") do set "_value=%%a"
if "!_value:~0,1!"=="\"" set "_value=!_value:~1!"
if "!_value:~-1!"=="," set "_value=!_value:~0,-1!"
if "!_value:~-1!"=="\"" set "_value=!_value:~0,-1!"
set "%~2=!_value!"
goto :eof

:RenderTemplate
set "_cmd=%~1"
set "_cmd=!_cmd:{version}=%OPENCLAW_VERSION%!"
set "_cmd=!_cmd:{package}=%OPENCLAW_PACKAGE%!"
set "_cmd=!_cmd:{registry}=%OPENCLAW_REGISTRY%!"
set "%~2=!_cmd!"
goto :eof

:DetectPnpm
set "PNPM_READY=0"
set "PNPM_GLOBAL_BIN="
set "PNPM_HOME="
where pnpm >nul 2>nul
if errorlevel 1 goto :eof

for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PNPM_HOME 2^>nul') do set "PNPM_HOME=%%b"
if defined PNPM_HOME if exist "!PNPM_HOME!" (
    set "PATH=!PNPM_HOME!;!PATH!"
    set "PNPM_READY=1"
    goto :eof
)

for /f "tokens=*" %%p in ('pnpm bin -g 2^>nul') do set "PNPM_GLOBAL_BIN=%%p"
if defined PNPM_GLOBAL_BIN if exist "!PNPM_GLOBAL_BIN!" (
    set "PATH=!PNPM_GLOBAL_BIN!;!PATH!"
    set "PNPM_READY=1"
)
goto :eof

:DetectNpmMirror
if defined BEST_NPM_MIRROR goto :eof
for /f "tokens=*" %%r in ('npm config get registry 2^>nul') do set "BEST_NPM_MIRROR=%%r"
if not defined BEST_NPM_MIRROR set "BEST_NPM_MIRROR=https://registry.npmmirror.com"
goto :eof

:: ============================================================
::  Main Flow
:: ============================================================
:Main
call :Info "Stage 3: Installing OpenClaw"
echo.

call :Info "OpenClaw version: !OPENCLAW_VERSION!"
call :Info "Package: !OPENCLAW_PACKAGE!"
call :Info "Registry: !OPENCLAW_REGISTRY!"

:: ---- Check if already installed ----
where openclaw >nul 2>nul
if not errorlevel 1 (
    call :Info "OpenClaw already installed - updating..."
    echo.

    :: Choose package manager: prefer pnpm if available and usable, otherwise npm
    set "UPDATE_PM=npm"
    if "!PNPM_READY!"=="1" (
        set "UPDATE_PM=pnpm"
    ) else (
        where pnpm >nul 2>nul
        if not errorlevel 1 (
            call :Warn "pnpm global bin not ready - falling back to npm update"
        )
    )

    echo ============================================================
    echo   Updating OpenClaw via !UPDATE_PM! ^(progress shown below^)
    echo ============================================================
    echo.
    if "!UPDATE_PM!"=="pnpm" (
        cmd /c "!RENDERED_PNPM_CMD!" 2>&1
        if errorlevel 1 (
            echo.
            call :Warn "pnpm update failed - trying npm as fallback..."
            cmd /c "!RENDERED_UPDATE_CMD!" 2>&1
            if errorlevel 1 (
                echo.
                call :Err "OpenClaw update failed via both pnpm and npm"
                exit /b 1
            )
            echo.
            call :Ok "OpenClaw updated via npm"
            goto :Done
        )
        echo.
        call :Ok "OpenClaw updated via pnpm"
        goto :Done
    )

    cmd /c "!RENDERED_UPDATE_CMD!" 2>&1
    if errorlevel 1 (
        echo.
        call :Err "OpenClaw update failed via both pnpm and npm"
        exit /b 1
    )
    echo.
    call :Ok "OpenClaw updated via npm"
    goto :Done
)

:: ---- Fresh install: prefer pnpm, fallback to npm ----
if "!PNPM_READY!"=="1" (
    echo.
    echo ============================================================
    echo   Installing OpenClaw via pnpm - this may take 1-3 minutes
    echo   Progress will be displayed below:
    echo ============================================================
    echo.
    cmd /c "!RENDERED_PNPM_CMD!" 2>&1
    if not errorlevel 1 (
        echo.
        call :Ok "OpenClaw installed via pnpm"
        goto :Done
    )
    echo.
    call :Warn "pnpm install failed - trying npm as fallback..."
)
if "!PNPM_READY!"=="0" (
    where pnpm >nul 2>nul
    if not errorlevel 1 call :Warn "pnpm global bin not ready - using npm directly"
)

:: ---- Fallback: npm ----
echo.
echo ============================================================
echo   Installing OpenClaw via npm - this may take 1-3 minutes
echo   Progress will be displayed below:
echo ============================================================
echo.
cmd /c "!RENDERED_INSTALL_CMD!" 2>&1
if errorlevel 1 (
    echo.
    call :Err "OpenClaw installation failed via both pnpm and npm"
    echo.
    echo  Troubleshooting:
    echo    1. Check git: where git
    echo    2. Test registry: curl !BEST_NPM_MIRROR!
    echo    3. Full log: %LOG%
    echo.
    echo  Manual install:
    echo    !RENDERED_PNPM_CMD!
    echo    or
    echo    !RENDERED_INSTALL_CMD!
    echo.
    exit /b 1
)
echo.
call :Ok "OpenClaw installed via npm"

:Done
echo.
call :Ok "Stage 3 complete - OpenClaw installed"
exit /b 0

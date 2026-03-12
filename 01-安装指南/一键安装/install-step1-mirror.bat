@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  Stage 1: Mirror Speed Test + Environment Configuration
:: ============================================================

if not defined LOG set "LOG=%TEMP%\openclaw-install.log"

:: Helper functions
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

:Main
call :Info "Stage 1: Testing mirror speeds and configuring environment"
echo.

:: ============================================================
::  Test mirror speeds
:: ============================================================
call :Info "Testing npm registry mirrors..."

set "TAOBAO_NPM=https://registry.npmmirror.com"
set "TENCENT_NPM=https://mirrors.cloud.tencent.com/npm/"
set "HUAWEI_NPM=https://mirrors.huaweicloud.com/repository/npm/"

set "TAOBAO_NODE=https://npmmirror.com/mirrors/node/"
set "TENCENT_NODE=https://mirrors.cloud.tencent.com/nodejs-release/"
set "HUAWEI_NODE=https://mirrors.huaweicloud.com/nodejs/"

set "BEST_NPM_MIRROR=%TAOBAO_NPM%"
set "BEST_NPM_NAME=Taobao"
set "BEST_NODE_MIRROR=%TAOBAO_NODE%"
set "BEST_NODE_NAME=Taobao"
set "BEST_TIME=9999"

:: Test Taobao
curl -s -m 3 -o nul "%TAOBAO_NPM%" 2>nul
if not errorlevel 1 (
    call :Ok "Taobao npm mirror: OK"
) else (
    call :Warn "Taobao npm mirror: timeout"
)

:: Test Tencent
curl -s -m 3 -o nul "%TENCENT_NPM%" 2>nul
if not errorlevel 1 (
    call :Ok "Tencent npm mirror: OK"
    set "BEST_NPM_MIRROR=%TENCENT_NPM%"
    set "BEST_NPM_NAME=Tencent"
) else (
    call :Warn "Tencent npm mirror: timeout"
)

call :Ok "Selected npm mirror: %BEST_NPM_NAME% (%BEST_NPM_MIRROR%)"
call :Ok "Selected Node mirror: %BEST_NODE_NAME% (%BEST_NODE_MIRROR%)"

:: ============================================================
::  Configure npm registry + prefix
:: ============================================================
echo.
call :Info "Configuring npm registry and global prefix..."

set "NPM_PREFIX=%APPDATA%\npm"
if not exist "%NPM_PREFIX%" mkdir "%NPM_PREFIX%" >nul 2>&1

:: Write user .npmrc
set "USER_NPMRC=%USERPROFILE%\.npmrc"
> "%USER_NPMRC%" echo registry=%BEST_NPM_MIRROR%
>> "%USER_NPMRC%" echo prefix=%NPM_PREFIX%
call :Ok "Written: %USER_NPMRC%"

:: Write global .npmrc
set "GLOBAL_NPMRC=%NPM_PREFIX%\etc\npmrc"
if not exist "%NPM_PREFIX%\etc" mkdir "%NPM_PREFIX%\etc" >nul 2>&1
> "%GLOBAL_NPMRC%" echo registry=%BEST_NPM_MIRROR%
>> "%GLOBAL_NPMRC%" echo prefix=%NPM_PREFIX%
call :Ok "Written: %GLOBAL_NPMRC%"

:: ============================================================
::  Configure environment variables
:: ============================================================
echo.
call :Info "Configuring environment variables (permanent)..."

:: Add npm prefix to PATH
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USR_PATH=%%b"
if not defined USR_PATH set "USR_PATH="

> "%TEMP%\_oc_pathcheck.tmp" echo !USR_PATH!
findstr /i /c:"npm" "%TEMP%\_oc_pathcheck.tmp" >nul 2>&1
del "%TEMP%\_oc_pathcheck.tmp" >nul 2>&1
if errorlevel 1 (
    setx PATH "!USR_PATH!;%NPM_PREFIX%" >nul 2>&1
    call :Ok "Added %NPM_PREFIX% to user PATH"
) else (
    call :Info "PATH already contains npm path"
)

:: Set NODE_MIRROR for future use
setx NODE_MIRROR "%BEST_NODE_MIRROR%" >nul 2>&1
call :Ok "NODE_MIRROR set to %BEST_NODE_NAME%"

:: Export variables for next stages
endlocal & (
    set "BEST_NPM_MIRROR=%BEST_NPM_MIRROR%"
    set "BEST_NPM_NAME=%BEST_NPM_NAME%"
    set "BEST_NODE_MIRROR=%BEST_NODE_MIRROR%"
    set "BEST_NODE_NAME=%BEST_NODE_NAME%"
    set "NPM_PREFIX=%NPM_PREFIX%"
)

echo.
call :Ok "Stage 1 complete"
exit /b 0

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

:Main

@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  Stage 1: Mirror Speed Test + Environment Configuration
:: ============================================================

if not defined LOG set "LOG=%TEMP%\openclaw-install.log"
if not defined SCRIPT_DIR set "SCRIPT_DIR=%~dp0"

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

:StoreMirror
set "MIRROR_VALUE=%~2"
set "MIRROR_VALUE=!MIRROR_VALUE:"=!"
if "!MIRROR_VALUE:~-1!"=="," set "MIRROR_VALUE=!MIRROR_VALUE:~0,-1!"
if /i "%~1"=="NODE" if not "!MIRROR_VALUE:~-1!"=="/" set "MIRROR_VALUE=!MIRROR_VALUE!/"

set "MIRROR_LABEL=Custom"
if /i not "!MIRROR_VALUE:npmmirror.com=!"=="!MIRROR_VALUE!" set "MIRROR_LABEL=Taobao"
if /i not "!MIRROR_VALUE:registry.npmmirror.com=!"=="!MIRROR_VALUE!" set "MIRROR_LABEL=Taobao"
if /i not "!MIRROR_VALUE:cloud.tencent.com=!"=="!MIRROR_VALUE!" set "MIRROR_LABEL=Tencent"
if /i not "!MIRROR_VALUE:huaweicloud.com=!"=="!MIRROR_VALUE!" set "MIRROR_LABEL=Huawei"

if /i "%~1"=="NPM" (
    set /a NPM_MIRROR_COUNT+=1
    set "NPM_MIRROR_!NPM_MIRROR_COUNT!=!MIRROR_VALUE!"
    set "NPM_MIRROR_NAME_!NPM_MIRROR_COUNT!=!MIRROR_LABEL!"
) else (
    set /a NODE_MIRROR_COUNT+=1
    set "NODE_MIRROR_!NODE_MIRROR_COUNT!=!MIRROR_VALUE!"
    set "NODE_MIRROR_NAME_!NODE_MIRROR_COUNT!=!MIRROR_LABEL!"
)
goto :eof

:SetDefaultMirrors
set "NPM_MIRROR_COUNT=3"
set "NPM_MIRROR_1=https://registry.npmmirror.com"
set "NPM_MIRROR_NAME_1=Taobao"
set "NPM_MIRROR_2=https://mirrors.cloud.tencent.com/npm/"
set "NPM_MIRROR_NAME_2=Tencent"
set "NPM_MIRROR_3=https://mirrors.huaweicloud.com/repository/npm/"
set "NPM_MIRROR_NAME_3=Huawei"

set "NODE_MIRROR_COUNT=3"
set "NODE_MIRROR_1=https://npmmirror.com/mirrors/node/"
set "NODE_MIRROR_NAME_1=Taobao"
set "NODE_MIRROR_2=https://mirrors.cloud.tencent.com/nodejs-release/"
set "NODE_MIRROR_NAME_2=Tencent"
set "NODE_MIRROR_3=https://mirrors.huaweicloud.com/nodejs/"
set "NODE_MIRROR_NAME_3=Huawei"
goto :eof

:ReadMirrorConfig
set "CONFIG_FILE=%SCRIPT_DIR%openclaw-install.json"
if defined OPENCLAW_CONFIG_FILE set "CONFIG_FILE=%OPENCLAW_CONFIG_FILE%"
if not exist "%CONFIG_FILE%" (
    call :Warn "Mirror config not found, using defaults: %CONFIG_FILE%"
    call :SetDefaultMirrors
    goto :eof
)

set "NPM_MIRROR_COUNT=0"
set "NODE_MIRROR_COUNT=0"
set "IN_MIRRORS=0"
set "IN_NPM=0"
set "IN_NODE=0"

for /f "usebackq delims=" %%L in ("%CONFIG_FILE%") do (
    set "LINE=%%L"
    set "LINE_TRIM=!LINE: =!"
    set "LINE_KEY=!LINE_TRIM:"=!"

    if /i "!LINE_KEY!"=="mirrors:{" set "IN_MIRRORS=1" & set "IN_NPM=0" & set "IN_NODE=0"

    if "!IN_MIRRORS!"=="1" (
        if /i "!LINE_KEY!"=="npm:[" set "IN_NPM=1" & set "IN_NODE=0"
        if /i "!LINE_KEY!"=="nodejs:[" set "IN_NODE=1" & set "IN_NPM=0"

        if "!IN_NPM!"=="1" (
            if /i not "!LINE_TRIM:https://=!"=="!LINE_TRIM!" call :StoreMirror NPM "!LINE_TRIM!"
            if /i "!LINE_TRIM!"=="]," set "IN_NPM=0"
            if /i "!LINE_TRIM!"=="]" set "IN_NPM=0"
        )

        if "!IN_NODE!"=="1" (
            if /i not "!LINE_TRIM:https://=!"=="!LINE_TRIM!" call :StoreMirror NODE "!LINE_TRIM!"
            if /i "!LINE_TRIM!"=="]," set "IN_NODE=0"
            if /i "!LINE_TRIM!"=="]" set "IN_NODE=0"
        )
    )
)

if "!NPM_MIRROR_COUNT!"=="0" (
    call :Warn "No npm mirrors found in config - using defaults"
    call :SetDefaultMirrors
    goto :eof
)

if "!NODE_MIRROR_COUNT!"=="0" (
    call :Warn "No Node.js mirrors found in config - using defaults"
    call :SetDefaultMirrors
)
goto :eof

:TestMirror
set "TEST_URL=%~1"
set "TEST_NAME=%~2"
set "TEST_LABEL=%~3"
set "TEST_OUT_VAR=%~4"
set "TEST_STATUS_VAR=%~5"
set "TEST_TIME_RAW="
set "TEST_TIME_MS="

for /f "delims=" %%T in ('curl -s -o nul -m 5 -w "%%{time_total}" "%TEST_URL%" 2^>nul') do set "TEST_TIME_RAW=%%T"
if not defined TEST_TIME_RAW (
    call :Warn "%TEST_NAME% %TEST_LABEL%: unavailable"
    set "%TEST_STATUS_VAR%=0"
    set "%TEST_OUT_VAR%=999999"
    goto :eof
)

set "TEST_TIME_MS=%TEST_TIME_RAW:.=%"
set "TEST_TIME_MS=%TEST_TIME_MS%000"
set "TEST_TIME_MS=%TEST_TIME_MS:~0,4%"

if not defined TEST_TIME_MS (
    call :Warn "%TEST_NAME% %TEST_LABEL%: unavailable"
    set "%TEST_STATUS_VAR%=0"
    set "%TEST_OUT_VAR%=999999"
    goto :eof
)

set /a TEST_TIME_MS=1%TEST_TIME_MS%-10000 >nul 2>&1
if errorlevel 1 (
    call :Warn "%TEST_NAME% %TEST_LABEL%: unavailable"
    set "%TEST_STATUS_VAR%=0"
    set "%TEST_OUT_VAR%=999999"
    goto :eof
)

call :Ok "%TEST_NAME% %TEST_LABEL%: !TEST_TIME_MS!ms"
set "%TEST_STATUS_VAR%=1"
set "%TEST_OUT_VAR%=!TEST_TIME_MS!"
goto :eof

:: ============================================================
::  Main Flow
:: ============================================================
:Main
call :Info "Stage 1: Testing mirror speeds and configuring environment"
echo.

call :ReadMirrorConfig

:: ============================================================
::  Test mirror speeds (available first, then pick lowest latency)
:: ============================================================
call :Info "Testing npm registry mirrors (all candidates, lowest latency among available)..."

:: Default values
call set "BEST_NPM_MIRROR=%%NPM_MIRROR_1%%"
call set "BEST_NPM_NAME=%%NPM_MIRROR_NAME_1%%"
call set "BEST_NODE_MIRROR=%%NODE_MIRROR_1%%"
call set "BEST_NODE_NAME=%%NODE_MIRROR_NAME_1%%"
set "BEST_NPM_MS=999999"
set "BEST_NODE_MS=999999"
set "NPM_AVAILABLE_COUNT=0"
set "NODE_AVAILABLE_COUNT=0"

:: Test npm mirrors - evaluate all candidates and pick the lowest latency among available
for /l %%i in (1,1,!NPM_MIRROR_COUNT!) do (
    call set "CUR_NPM_MIRROR=%%NPM_MIRROR_%%i%%"
    call set "CUR_NPM_NAME=%%NPM_MIRROR_NAME_%%i%%"
    call :TestMirror "!CUR_NPM_MIRROR!" "!CUR_NPM_NAME!" "npm mirror" CUR_NPM_MS CUR_NPM_OK
    if "!CUR_NPM_OK!"=="1" (
        set /a NPM_AVAILABLE_COUNT+=1
        if !CUR_NPM_MS! LSS !BEST_NPM_MS! (
            set "BEST_NPM_MIRROR=!CUR_NPM_MIRROR!"
            set "BEST_NPM_NAME=!CUR_NPM_NAME!"
            set "BEST_NPM_MS=!CUR_NPM_MS!"
        )
    )
)

if "!NPM_AVAILABLE_COUNT!"=="0" call :Warn "All npm mirrors failed - using default: !BEST_NPM_NAME!"

:NpmMirrorDone
if "!NPM_AVAILABLE_COUNT!"=="0" (
    call :Ok "Selected npm mirror: !BEST_NPM_NAME! (!BEST_NPM_MIRROR!) [fallback]"
) else (
    call :Ok "Selected npm mirror: !BEST_NPM_NAME! (!BEST_NPM_MIRROR!, !BEST_NPM_MS!ms)"
)

:: Test Node.js download mirrors - evaluate all candidates and pick the lowest latency among available
call :Info "Testing Node.js download mirrors (all candidates, lowest latency among available)..."

for /l %%i in (1,1,!NODE_MIRROR_COUNT!) do (
    call set "CUR_NODE_MIRROR=%%NODE_MIRROR_%%i%%"
    call set "CUR_NODE_NAME=%%NODE_MIRROR_NAME_%%i%%"
    call :TestMirror "!CUR_NODE_MIRROR!" "!CUR_NODE_NAME!" "node mirror" CUR_NODE_MS CUR_NODE_OK
    if "!CUR_NODE_OK!"=="1" (
        set /a NODE_AVAILABLE_COUNT+=1
        if !CUR_NODE_MS! LSS !BEST_NODE_MS! (
            set "BEST_NODE_MIRROR=!CUR_NODE_MIRROR!"
            set "BEST_NODE_NAME=!CUR_NODE_NAME!"
            set "BEST_NODE_MS=!CUR_NODE_MS!"
        )
    )
)

if "!NODE_AVAILABLE_COUNT!"=="0" call :Warn "All node mirrors failed - using default: !BEST_NODE_NAME!"

:NodeMirrorDone
if "!NODE_AVAILABLE_COUNT!"=="0" (
    call :Ok "Selected Node mirror: !BEST_NODE_NAME! (!BEST_NODE_MIRROR!) [fallback]"
) else (
    call :Ok "Selected Node mirror: !BEST_NODE_NAME! (!BEST_NODE_MIRROR!, !BEST_NODE_MS!ms)"
)

:: ============================================================
::  Configure npm registry + prefix
:: ============================================================
echo.
call :Info "Configuring npm registry and global prefix..."

set "NPM_PREFIX=%APPDATA%\npm"
if not exist "%NPM_PREFIX%" mkdir "%NPM_PREFIX%" >nul 2>&1

:: Write user .npmrc
set "USER_NPMRC=%USERPROFILE%\.npmrc"
> "%USER_NPMRC%" echo registry=!BEST_NPM_MIRROR!
>> "%USER_NPMRC%" echo prefix=%NPM_PREFIX%
call :Ok "Written: %USER_NPMRC%"

:: Write global .npmrc
set "GLOBAL_NPMRC=%NPM_PREFIX%\etc\npmrc"
if not exist "%NPM_PREFIX%\etc" mkdir "%NPM_PREFIX%\etc" >nul 2>&1
> "%GLOBAL_NPMRC%" echo registry=!BEST_NPM_MIRROR!
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
    call :Info "Writing npm path to registry..."
    setx PATH "!USR_PATH!;%NPM_PREFIX%" >nul 2>&1
    call :Ok "Added %NPM_PREFIX% to user PATH"
) else (
    call :Info "PATH already contains npm path"
)

:: Set NODE_MIRROR for future use
call :Info "Writing NODE_MIRROR to registry..."
setx NODE_MIRROR "!BEST_NODE_MIRROR!" >nul 2>&1
call :Ok "NODE_MIRROR set to !BEST_NODE_NAME!"

echo.
call :Ok "Stage 1 complete"

:: Export variables for next stages (must be last - endlocal exits scope)
endlocal & (
    set "BEST_NPM_MIRROR=%BEST_NPM_MIRROR%"
    set "BEST_NPM_NAME=%BEST_NPM_NAME%"
    set "BEST_NODE_MIRROR=%BEST_NODE_MIRROR%"
    set "BEST_NODE_NAME=%BEST_NODE_NAME%"
    set "NPM_PREFIX=%NPM_PREFIX%"
)
exit /b 0

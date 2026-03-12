@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  Edge Remote Debug Launcher
::  - 自动查找 Edge 路径
::  - 创建桌面快捷方式（如不存在）
::  - 检测 remote debug 是否已启动，未启动则自动启动
:: ============================================================

set "DEBUG_PORT=9222"
set "DEBUG_USER_DATA=D:\temp\chrome-debug"
set "SHORTCUT_NAME=Edge Remote Debug.lnk"
set "DESKTOP="
set "DESKTOP_FALLBACK=%USERPROFILE%\Desktop"
set "PUBLIC_DESKTOP=%PUBLIC%\Desktop"
set "SHORTCUT_LOG=%~dp0start-edge-debug-shortcut.log"

echo.
echo ============================================================
echo   Edge Remote Debug Launcher
echo   Port: %DEBUG_PORT%
echo ============================================================
echo.

:: ============================================================
::  Step 1: 查找 Edge 可执行文件路径
:: ============================================================
echo [ INFO ] Step 1: Searching for Microsoft Edge...

set "EDGE_EXE="

:: 常见安装路径（按优先级检查）
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    set "EDGE_EXE=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
)
if not defined EDGE_EXE (
    if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
        set "EDGE_EXE=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    )
)
if not defined EDGE_EXE (
    if exist "!LOCALAPPDATA!\Microsoft\Edge\Application\msedge.exe" (
        set "EDGE_EXE=!LOCALAPPDATA!\Microsoft\Edge\Application\msedge.exe"
    )
)

:: 通过注册表查找（安装路径可能不标准）
if not defined EDGE_EXE (
    for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /ve 2^>nul') do (
        set "EDGE_EXE=%%b"
    )
)

if not defined EDGE_EXE (
    echo [ERROR] Microsoft Edge not found
    echo         Please install Edge: https://www.microsoft.com/edge
    echo.
    pause
    exit /b 1
)

echo [  OK  ] Edge found: !EDGE_EXE!

:: ============================================================
::  Step 2: 检查桌面快捷方式，不存在则创建
:: ============================================================
echo.
echo [ INFO ] Step 2: Checking desktop shortcut...

call :ResolveDesktopPath
if not defined DESKTOP (
    set "DESKTOP=%~dp0"
    echo [ WARN ] Desktop path not found - fallback to script directory: !DESKTOP!
)

if not exist "!DESKTOP!" (
    echo [ INFO ] Desktop directory not found, creating: !DESKTOP!
    mkdir "!DESKTOP!" >nul 2>&1
)

if not exist "!DESKTOP!" (
    echo [ WARN ] Failed to prepare desktop directory - fallback to script directory
    set "DESKTOP=%~dp0"
)

set "SHORTCUT_PATH=!DESKTOP!\!SHORTCUT_NAME!"
echo [ INFO ] Shortcut target path: !SHORTCUT_PATH!

if exist "!SHORTCUT_PATH!" (
    echo [  OK  ] Shortcut already exists: !SHORTCUT_PATH!
) else (
    echo [ INFO ] Creating desktop shortcut...

    :: 用 PowerShell 创建 .lnk 快捷方式（CMD 无原生支持）
    set "TARGET=!EDGE_EXE!"
    set "ARGS=--remote-debugging-port=!DEBUG_PORT! --user-data-dir=!DEBUG_USER_DATA!"
    set "DESC=Edge with Remote Debugging on port !DEBUG_PORT!"

    del /q "!SHORTCUT_LOG!" >nul 2>&1
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ErrorActionPreference = 'Stop'; " ^
        "$shortcutPath = [IO.Path]::GetFullPath('!SHORTCUT_PATH!'); " ^
        "$shortcutDir = Split-Path -Parent $shortcutPath; " ^
        "if (-not (Test-Path -LiteralPath $shortcutDir)) { New-Item -ItemType Directory -Path $shortcutDir -Force | Out-Null }; " ^
        "$ws = New-Object -ComObject WScript.Shell; " ^
        "$sc = $ws.CreateShortcut($shortcutPath); " ^
        "$sc.TargetPath = '!TARGET!'; " ^
        "$sc.Arguments = '!ARGS!'; " ^
        "$sc.Description = '!DESC!'; " ^
        "$sc.WorkingDirectory = [System.IO.Path]::GetDirectoryName('!TARGET!'); " ^
        "$sc.Save()" >"!SHORTCUT_LOG!" 2>&1

    if exist "!SHORTCUT_PATH!" (
        echo [  OK  ] Shortcut created: !SHORTCUT_PATH!
    ) else (
        echo [ WARN ] Failed to create shortcut - will launch directly
        if exist "!SHORTCUT_LOG!" (
            echo [ WARN ] Shortcut log: !SHORTCUT_LOG!
        )
    )
)

:: ============================================================
::  Step 3: 检测 remote debug 是否已在运行
:: ============================================================
echo.
echo [ INFO ] Step 3: Checking if remote debug is already active (port !DEBUG_PORT!)...

call :IsEdgeRemoteDebugRunning
if "!EDGE_REMOTE_DEBUG_RUNNING!"=="1" (
    echo [  OK  ] Remote debug already running on port !DEBUG_PORT!
    echo.
    echo          You can connect via: http://localhost:!DEBUG_PORT!/json
    echo.
    pause
    exit /b 0
)

:: ============================================================
::  Step 4: 未运行，启动 Edge remote debug
:: ============================================================
echo [ WARN ] Remote debug not active - launching Edge...
echo.

:: 确保 user-data-dir 存在
if not exist "!DEBUG_USER_DATA!" (
    mkdir "!DEBUG_USER_DATA!" >nul 2>&1
    echo [ INFO ] Created user data dir: !DEBUG_USER_DATA!
)

:: 优先用快捷方式启动（与快捷方式行为保持一致）
if exist "!SHORTCUT_PATH!" (
    echo [ INFO ] Launching via desktop shortcut...
    start "" "!SHORTCUT_PATH!"
) else (
    echo [ INFO ] Launching directly...
    start "" "!EDGE_EXE!" --remote-debugging-port=!DEBUG_PORT! --user-data-dir=!DEBUG_USER_DATA!
)

:: 轮询等待端口就绪（最多 15 秒）
echo [ INFO ] Waiting for remote debug port to open...
set "WAITED=0"
set "MAX_WAIT=15"

:WaitLoop
if !WAITED! GEQ !MAX_WAIT! goto :WaitTimeout

call :IsEdgeRemoteDebugRunning
if "!EDGE_REMOTE_DEBUG_RUNNING!"=="1" goto :WaitSuccess

timeout /t 1 /nobreak >nul
set /a "WAITED+=1"
<nul set /p "=."
goto :WaitLoop

:WaitSuccess
echo.
echo [  OK  ] Edge remote debug is ready! (waited !WAITED!s)
echo.
echo          Connect URL : http://localhost:!DEBUG_PORT!/json
echo          User data   : !DEBUG_USER_DATA!
echo.
pause
exit /b 0

:WaitTimeout
echo.
echo [ WARN ] Port !DEBUG_PORT! not detected after !MAX_WAIT!s
echo          Edge may still be starting - try connecting manually:
echo          http://localhost:!DEBUG_PORT!/json
echo.
pause
exit /b 1

:IsEdgeRemoteDebugRunning
set "EDGE_REMOTE_DEBUG_RUNNING=0"
for /f "tokens=5" %%p in ('netstat -ano -p tcp 2^>nul ^| findstr /r /c:":!DEBUG_PORT! .*LISTENING"') do (
    tasklist /FI "PID eq %%p" /FI "IMAGENAME eq msedge.exe" 2>nul | findstr /i "msedge.exe" >nul 2>&1
    if not errorlevel 1 (
        set "EDGE_REMOTE_DEBUG_RUNNING=1"
        goto :eof
    )
)
goto :eof

:ResolveDesktopPath
set "DESKTOP="
for /f "skip=2 tokens=2,*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop 2^>nul') do (
    set "DESKTOP=%%b"
)
if defined DESKTOP call set "DESKTOP=%%DESKTOP%%"
if defined DESKTOP if exist "!DESKTOP!" goto :eof

set "DESKTOP=!DESKTOP_FALLBACK!"
if exist "!DESKTOP!" goto :eof

set "DESKTOP=!PUBLIC_DESKTOP!"
if exist "!DESKTOP!" goto :eof

set "DESKTOP="
goto :eof

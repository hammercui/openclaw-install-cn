@echo off
setlocal

echo [ INFO ] 请先在 Chrome 打开：
echo         chrome://inspect/#remote-debugging
echo         并勾选 Allow remote debugging for this browser instance
echo.

openclaw browser --browser-profile user start
if errorlevel 1 exit /b 1

openclaw browser --browser-profile user status
exit /b %errorlevel%

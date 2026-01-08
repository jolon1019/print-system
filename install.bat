@echo off
cd /d "%~dp0"

echo ========================================
echo Hot Roll Print Management - Install
echo ========================================
echo.

echo Step 1/3: Copying service files...
echo.

if exist "..\print-server.js" (
    copy "..\print-server.js" ".\print-server.js" >nul
    echo [OK] print-server.js copied
) else (
    echo [WARN] print-server.js not found
)

if exist "..\printer-client.js" (
    copy "..\printer-client.js" ".\printer-client.js" >nul
    echo [OK] printer-client.js copied
) else (
    echo [WARN] printer-client.js not found
)

if exist "..\python_monitor.py" (
    copy "..\python_monitor.py" ".\python_monitor.py" >nul
    echo [OK] python_monitor.py copied
) else (
    echo [WARN] python_monitor.py not found
)

echo.
echo Step 2/3: Installing dependencies...
echo.

if not exist "node_modules" (
    call npm install
    if errorlevel 1 (
        echo.
        echo [ERROR] Dependency installation failed!
        pause
        exit /b 1
    )
) else (
    echo [INFO] Dependencies already exist, skipping installation
)

echo.
echo Step 3/3: Installation complete!
echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
echo You can now run start.bat to start the application
echo.
pause

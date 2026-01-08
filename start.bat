@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0"

echo ========================================
echo Hot Roll Print Management - Start
echo ========================================
echo.

if not exist "node_modules" (
    echo [INFO] First run, installing dependencies...
    echo.
    call npm install
    echo.
    echo [INFO] Dependencies installed!
    echo.
)

echo [INFO] Starting application...
echo.
npm start

@echo off
echo ========================================
echo    Kill processes using port 17026
echo ========================================
echo.

echo [1/3] Finding processes using port 17026...
netstat -ano | findstr :17026

echo.
echo [2/3] Killing all processes using port 17026...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :17026') do (
    echo Killing process PID: %%a
    taskkill /F /PID %%a
)

echo.
echo [3/3] Verifying port status...
netstat -ano | findstr :17026
if errorlevel 1 (
    echo Port 17026 is now free
) else (
    echo Warning: Port 17026 is still in use
)

echo.
echo ========================================
echo    Operation completed
echo ========================================
pause
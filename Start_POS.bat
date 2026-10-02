@echo off
title POS Cloud - Starter
echo [1/3] Closing existing instances...
taskkill /f /im dotnet.exe 2>nul

echo [2/3] Starting POS Backend...
set ASPNETCORE_ENVIRONMENT=Development
set Jwt__Key=DEV_ONLY_NOT_FOR_PRODUCTION_32+_CHANGE_ME_LOCAL_DEV_KEY_1234567890

:: Start the API in a new hidden/minimized window
start /min "POS_API" "D:\dotnet10\dotnet.exe" "D:\POS\backend\src\PosCloud.Api\bin\Debug\net10.0\PosCloud.Api.dll" --urls http://0.0.0.0:5000

echo [3/3] Waiting for system to initialize...
timeout /t 5 /nobreak >nul

echo Launching Browser...
start http://localhost:5000

echo.
echo ==========================================
echo    POS System is now RUNNING!
echo    URL: http://localhost:5000
echo ==========================================
pause

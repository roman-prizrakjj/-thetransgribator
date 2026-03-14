@echo off
title Transgribator

echo ============================================
echo   Transgribator - Setup and Launch
echo ============================================
echo.

:: --- Check Python ---
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Python not found.
    echo.
    echo     Download and install Python:
    echo     https://www.python.org/downloads/
    echo.
    echo     IMPORTANT: check "Add Python to PATH" during install
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYVER=%%i
echo [OK] %PYVER%

:: --- Check / install ffmpeg ---
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo [..] ffmpeg not found, downloading...
    echo.

    set "FFMPEG_DIR=%~dp0ffmpeg"
    set "FFMPEG_ZIP=%~dp0ffmpeg.zip"
    set "FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"

    if not exist "%FFMPEG_DIR%" mkdir "%FFMPEG_DIR%"

    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Write-Host 'Downloading ffmpeg (~90 MB)...'; Invoke-WebRequest -Uri '%FFMPEG_URL%' -OutFile '%FFMPEG_ZIP%'"

    if not exist "%FFMPEG_ZIP%" (
        echo [!] Failed to download ffmpeg.
        echo     Download manually: https://ffmpeg.org/download.html
        pause
        exit /b 1
    )

    echo [..] Extracting...
    powershell -Command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%FFMPEG_DIR%' -Force"
    del "%FFMPEG_ZIP%" 2>nul

    for /r "%FFMPEG_DIR%" %%f in (ffmpeg.exe) do (
        set "FFMPEG_BIN_DIR=%%~dpf"
        goto :found_ffmpeg
    )

    echo [!] ffmpeg.exe not found in archive.
    pause
    exit /b 1

    :found_ffmpeg
    set "PATH=%FFMPEG_BIN_DIR%;%PATH%"

    where ffmpeg >nul 2>&1
    if %errorlevel% neq 0 (
        echo [!] ffmpeg extracted but not accessible.
        pause
        exit /b 1
    )

    echo [OK] ffmpeg downloaded: %FFMPEG_BIN_DIR%
    echo.
) else (
    echo [OK] ffmpeg found
)

echo.
echo ============================================
echo   Starting server...
echo   http://localhost:8765/transcriber.html
echo ============================================
echo.

:: Open browser after 2 sec delay (gives server time to start)
start "" cmd /c "ping -n 3 127.0.0.1 >nul && start http://localhost:8765/transcriber.html"

:: Run server (blocks until Ctrl+C)
python "%~dp0server.py"
pause

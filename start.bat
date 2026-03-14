@echo off
chcp 65001 >nul 2>&1
title Transgribator

echo ============================================
echo   Transgribator - Setup ^& Launch
echo ============================================
echo.

:: --- Проверка Python ---
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Python не найден.
    echo.
    echo     Скачай и установи Python:
    echo     https://www.python.org/downloads/
    echo.
    echo     ВАЖНО: при установке поставь галочку "Add Python to PATH"
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYVER=%%i
echo [OK] %PYVER%

:: --- Проверка / установка ffmpeg ---
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo [..] ffmpeg не найден, скачиваю...
    echo.

    set "FFMPEG_DIR=%~dp0ffmpeg"
    set "FFMPEG_ZIP=%~dp0ffmpeg.zip"
    set "FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"

    if not exist "%FFMPEG_DIR%" mkdir "%FFMPEG_DIR%"

    :: Скачиваем через PowerShell (есть везде на Win 10/11)
    powershell -Command "Write-Host 'Downloading ffmpeg (~90 MB)...'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%FFMPEG_URL%' -OutFile '%FFMPEG_ZIP%'"

    if not exist "%FFMPEG_ZIP%" (
        echo [!] Не удалось скачать ffmpeg.
        echo     Скачай вручную: https://ffmpeg.org/download.html
        pause
        exit /b 1
    )

    echo [..] Распаковка...
    powershell -Command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%FFMPEG_DIR%' -Force"
    del "%FFMPEG_ZIP%" 2>nul

    :: Найти bin/ffmpeg.exe внутри распакованной папки
    for /r "%FFMPEG_DIR%" %%f in (ffmpeg.exe) do (
        set "FFMPEG_BIN_DIR=%%~dpf"
        goto :found_ffmpeg
    )

    echo [!] ffmpeg.exe не найден в архиве.
    pause
    exit /b 1

    :found_ffmpeg
    :: Добавить в PATH для текущей сессии
    set "PATH=%FFMPEG_BIN_DIR%;%PATH%"

    where ffmpeg >nul 2>&1
    if %errorlevel% neq 0 (
        echo [!] ffmpeg установлен, но не найден в PATH.
        pause
        exit /b 1
    )

    echo [OK] ffmpeg скачан и готов к работе
    echo     Расположение: %FFMPEG_BIN_DIR%
    echo.
) else (
    echo [OK] ffmpeg найден
)

echo.
echo ============================================
echo   Запуск сервера...
echo   http://localhost:8765/transcriber.html
echo ============================================
echo.

:: Открыть браузер
start "" "http://localhost:8765/transcriber.html"

:: Запустить сервер
python "%~dp0server.py"
pause

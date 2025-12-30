@echo off
setlocal ENABLEDELAYEDEXPANSION

REM One-click wrapper: convert PDF to WAV using interactive voice picker
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%pdf_to_audio.ps1"

if "%~1"=="" (
  set /p PDF="Enter PDF path: "
) else (
  set "PDF=%~1"
)

if not exist "%PDF%" (
  echo Input PDF not found: "%PDF%"
  exit /b 1
)

for %%I in ("%PDF%") do set "OUT=%%~dpnI.wav"

"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -PdfPath "%PDF%" -OutPath "%OUT%" -PickVoice
if errorlevel 1 (
  echo Conversion failed.
  exit /b 1
)

echo Done. Wrote: "%OUT%"
endlocal

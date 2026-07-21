@echo off
setlocal

echo Starting Autobiography app in dev mode...

if "%PORT%"=="" set PORT=3000

if exist "tmp\pids\server.pid" (
  echo Removing stale Rails PID lock: tmp\pids\server.pid
  del /f /q "tmp\pids\server.pid"
)

where foreman >nul 2>nul
if errorlevel 1 (
  echo Foreman is not installed. Installing now...
  gem install foreman
  if errorlevel 1 (
    echo Failed to install Foreman. Please run: gem install foreman
    exit /b 1
  )
)

echo Launching Rails server + Tailwind watcher...
foreman start -f Procfile.dev

endlocal

@echo off
setlocal enabledelayedexpansion

REM Bingo Server Ping Monitor - Windows Batch Script
REM This script provides easy access to the Python ping monitor on Windows

set "SCRIPT_DIR=%~dp0"
set "PYTHON_SCRIPT=%SCRIPT_DIR%ping-monitor.py"

REM Default values
set "MODE=continuous"
set "SERVER_URL=https://cheap-bingo-go-server.onrender.com"
set "INTERVAL=30"
set "TIMEOUT=10"
set "ALERT_THRESHOLD=3"

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :end_parse
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-s" goto :set_single
if /i "%~1"=="--single" goto :set_single
if /i "%~1"=="-w" goto :set_websocket
if /i "%~1"=="--websocket" goto :set_websocket
if /i "%~1"=="-u" goto :set_url
if /i "%~1"=="--url" goto :set_url
if /i "%~1"=="-i" goto :set_interval
if /i "%~1"=="--interval" goto :set_interval
if /i "%~1"=="-t" goto :set_timeout
if /i "%~1"=="--timeout" goto :set_timeout
if /i "%~1"=="-a" goto :set_alert
if /i "%~1"=="--alert" goto :set_alert
echo [ERROR] Unknown option: %~1
goto :show_help

:set_single
set "MODE=single"
shift
goto :parse_args

:set_websocket
set "MODE=websocket"
shift
goto :parse_args

:set_url
set "SERVER_URL=%~2"
shift
shift
goto :parse_args

:set_interval
set "INTERVAL=%~2"
shift
shift
goto :parse_args

:set_timeout
set "TIMEOUT=%~2"
shift
shift
goto :parse_args

:set_alert
set "ALERT_THRESHOLD=%~2"
shift
shift
goto :parse_args

:end_parse

REM Show help if requested
if "%1"=="" goto :check_prerequisites
goto :check_prerequisites

:show_help
echo.
echo 🎯 Bingo Server Ping Monitor
echo.
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   -h, --help           Show this help message
echo   -s, --single         Run single health check and exit
echo   -w, --websocket      Test WebSocket connection only
echo   -u, --url URL        Custom server URL (default: https://cheap-bingo-go-server.onrender.com)
echo   -i, --interval SEC   Check interval in seconds (default: 30)
echo   -t, --timeout SEC    Request timeout in seconds (default: 10)
echo   -a, --alert NUM      Alert threshold for consecutive failures (default: 3)
echo.
echo Examples:
echo   %~nx0                    # Start continuous monitoring
echo   %~nx0 -s                 # Run single health check
echo   %~nx0 -w                 # Test WebSocket connection
echo   %~nx0 -i 60              # Check every 60 seconds
echo   %~nx0 -u https://my-server.com  # Custom server URL
echo.
pause
exit /b 0

:check_prerequisites
echo [INFO] Checking prerequisites...

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH
    echo [INFO] Please install Python 3.7+ and try again
    echo [INFO] Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Check Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set "PYTHON_VERSION=%%i"
echo [INFO] Python %PYTHON_VERSION% found

REM Check if required packages are installed
echo [INFO] Checking dependencies...
python -c "import requests, websocket" >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Required packages not found. Installing...
    
    if exist "%SCRIPT_DIR%requirements.txt" (
        echo [INFO] Installing from requirements.txt...
        pip install -r "%SCRIPT_DIR%requirements.txt"
    ) else (
        echo [INFO] Installing required packages...
        pip install requests websocket-client
    )
    
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install required packages
        pause
        exit /b 1
    )
    
    echo [INFO] Dependencies installed successfully
) else (
    echo [INFO] All dependencies are available
)

REM Build command
set "CMD=python %PYTHON_SCRIPT%"

if "%MODE%"=="single" (
    set "CMD=%CMD% --single"
    echo [INFO] Running single health check...
) else if "%MODE%"=="websocket" (
    set "CMD=%CMD% --test-ws"
    echo [INFO] Testing WebSocket connection...
) else (
    echo [INFO] Starting continuous monitoring...
    echo [INFO] Server: %SERVER_URL%
    echo [INFO] Interval: %INTERVAL%s
    echo [INFO] Timeout: %TIMEOUT%s
    echo [INFO] Alert threshold: %ALERT_THRESHOLD%
    echo.
)

REM Add custom parameters
set "CMD=%CMD% --url %SERVER_URL% --interval %INTERVAL% --timeout %TIMEOUT% --threshold %ALERT_THRESHOLD%"

REM Execute the command
echo [INFO] Executing: %CMD%
echo.
%CMD%

REM Pause at the end if not in continuous mode
if not "%MODE%"=="continuous" (
    echo.
    pause
)

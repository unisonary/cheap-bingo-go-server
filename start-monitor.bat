@echo off
echo 🎯 Starting Bingo Server Ping Monitor...
echo.
cd ping-monitor
echo Changed to ping-monitor directory
echo.
echo Available commands:
echo   ping-monitor.bat        - Start continuous monitoring
echo   ping-monitor.bat -s     - Run single health check
echo   ping-monitor.bat -w     - Test WebSocket connection
echo   ping-monitor.bat -h     - Show help
echo.
echo Starting monitor...
ping-monitor.bat
pause

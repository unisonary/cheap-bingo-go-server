# 🎯 Bingo Server Ping Monitor

A self-hosted monitoring solution to check the health of your Bingo server deployed on Render.com. This monitor continuously checks both HTTP endpoints and WebSocket connectivity to ensure your service is running properly.

## ✨ Features

- **HTTP Health Checks**: Monitors home page and health endpoint
- **WebSocket Connectivity**: Tests real-time WebSocket connections
- **Continuous Monitoring**: Runs 24/7 with configurable intervals
- **Alert System**: Notifies when consecutive failures exceed threshold
- **Statistics Tracking**: Detailed success/failure rates and uptime
- **Cross-Platform**: Works on Windows, macOS, and Linux
- **Easy Setup**: Automatic dependency installation and configuration

## 🚀 Quick Start

### Prerequisites

- **Python 3.7+** installed on your system
- **Internet connection** to reach your Render.com service

### Installation

1. **Download the files** to your local machine
2. **Make scripts executable** (Linux/macOS):
   ```bash
   chmod +x ping-monitor.sh
   chmod +x ping-monitor.py
   ```

3. **Install dependencies** (automatic):
   ```bash
   pip install -r requirements.txt
   ```

## 📱 Usage

### Option 1: Shell Script (Linux/macOS)

```bash
# Start continuous monitoring (default: every 30 seconds)
./ping-monitor.sh

# Run single health check
./ping-monitor.sh -s

# Test WebSocket connection only
./ping-monitor.sh -w

# Custom check interval (60 seconds)
./ping-monitor.sh -i 60

# Custom server URL
./ping-monitor.sh -u https://my-custom-server.com

# Show help
./ping-monitor.sh -h
```

### Option 2: Windows Batch File

```cmd
# Start continuous monitoring
ping-monitor.bat

# Run single health check
ping-monitor.bat -s

# Test WebSocket connection only
ping-monitor.bat -w

# Custom check interval (60 seconds)
ping-monitor.bat -i 60

# Show help
ping-monitor.bat -h
```

### Option 3: Direct Python Execution

```bash
# Start continuous monitoring
python3 ping-monitor.py

# Run single health check
python3 ping-monitor.py --single

# Test WebSocket connection only
python3 ping-monitor.py --test-ws

# Custom configuration
python3 ping-monitor.py --interval 60 --timeout 15 --threshold 5
```

## ⚙️ Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `--url` | Server URL to monitor | `https://cheap-bingo-go-server.onrender.com` |
| `--interval` | Check interval in seconds | `30` |
| `--timeout` | Request timeout in seconds | `10` |
| `--threshold` | Alert threshold for consecutive failures | `3` |
| `--single` | Run single check and exit | `False` |
| `--test-ws` | Test WebSocket only | `False` |

## 📊 What Gets Monitored

### 1. HTTP Endpoints
- **Home Page** (`/`): Should return "Home Page"
- **Health Endpoint** (`/healthz`): Should return "ok"

### 2. WebSocket Connection
- **Connection**: Establishes WebSocket connection to `/ws`
- **Message Sending**: Sends test ping message
- **Response Handling**: Waits for server response

### 3. Response Times
- **HTTP Response Time**: Measures how fast your server responds
- **WebSocket Connection Time**: Measures WebSocket handshake speed

## 🔔 Alert System

The monitor will trigger alerts when:
- **Consecutive failures** exceed the alert threshold (default: 3)
- **WebSocket connection** fails repeatedly
- **HTTP endpoints** return error status codes

### Alert Example
```
🚨 ALERT: Bingo server has failed 3 consecutive health checks!
Server: https://cheap-bingo-go-server.onrender.com
Time: 2025-08-29 15:30:45
```

## 📈 Statistics Dashboard

The monitor provides real-time statistics:

```
📊 BINGO SERVER MONITOR STATISTICS
============================================================
Server URL: https://cheap-bingo-go-server.onrender.com
Monitor Uptime: 2:15:30
Started: 2025-08-29 13:15:15

HTTP Checks: 270
HTTP Success: 268 (99.3%)
HTTP Failures: 2

WebSocket Checks: 270
WebSocket Success: 269 (99.6%)
WebSocket Failures: 1

Last Success: 2025-08-29 15:30:45
Last Failure: 2025-08-29 15:25:15
Consecutive Failures: 0
============================================================
```

## 🛠️ Customization

### Extending Alert Notifications

You can modify the `send_alert()` method in `ping-monitor.py` to add:

- **Email notifications** via SMTP
- **Slack messages** via webhook
- **Discord notifications** via webhook
- **SMS alerts** via Twilio
- **Push notifications** via services like Pushover

Example Slack integration:
```python
def send_slack_alert(self, message):
    webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    slack_data = {"text": message}
    requests.post(webhook_url, json=slack_data)
```

### Custom Health Checks

Add your own health checks by extending the `perform_health_check()` method:

```python
def check_custom_endpoint(self):
    """Check custom endpoint"""
    try:
        response = requests.get(f"{self.base_url}/custom-endpoint")
        return response.status_code == 200
    except:
        return False
```

## 🚨 Troubleshooting

### Common Issues

1. **Python not found**
   ```bash
   # Install Python 3.7+
   # Windows: Download from python.org
   # macOS: brew install python3
   # Linux: sudo apt install python3
   ```

2. **Dependencies missing**
   ```bash
   pip install requests websocket-client
   ```

3. **Permission denied** (Linux/macOS)
   ```bash
   chmod +x ping-monitor.sh
   ```

4. **WebSocket connection fails**
   - Check if your server supports WebSocket upgrades
   - Verify the `/ws` endpoint is accessible
   - Check firewall/proxy settings

### Debug Mode

Run with verbose output:
```bash
python3 ping-monitor.py --test-ws
```

## 📱 Running as a Service

### Linux/macOS (systemd)

Create a service file `/etc/systemd/system/bingo-monitor.service`:

```ini
[Unit]
Description=Bingo Server Monitor
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/monitor
ExecStart=/path/to/monitor/ping-monitor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable bingo-monitor
sudo systemctl start bingo-monitor
sudo systemctl status bingo-monitor
```

### Windows (Task Scheduler)

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger (e.g., at startup)
4. Set action to start `ping-monitor.bat`
5. Run whether user is logged in or not

## 🔧 Advanced Configuration

### Environment Variables

Set these environment variables for custom configuration:

```bash
export BINGO_SERVER_URL="https://my-server.com"
export BINGO_CHECK_INTERVAL="60"
export BINGO_TIMEOUT="15"
export BINGO_ALERT_THRESHOLD="5"
```

### Configuration File

Create `config.json` for persistent settings:

```json
{
    "server_url": "https://cheap-bingo-go-server.onrender.com",
    "check_interval": 30,
    "timeout": 10,
    "alert_threshold": 3,
    "alert_webhook": "https://hooks.slack.com/services/...",
    "custom_endpoints": [
        "/api/health",
        "/status"
    ]
}
```

## 📊 Monitoring Multiple Servers

Run multiple monitor instances for different servers:

```bash
# Terminal 1: Monitor production server
./ping-monitor.sh -u https://prod-bingo.onrender.com -i 30

# Terminal 2: Monitor staging server  
./ping-monitor.sh -u https://staging-bingo.onrender.com -i 60

# Terminal 3: Monitor development server
./ping-monitor.sh -u https://dev-bingo.onrender.com -i 120
```

## 🤝 Contributing

Feel free to contribute improvements:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

This monitoring solution is provided as-is for educational and operational purposes.

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify your Python version (3.7+)
3. Ensure all dependencies are installed
4. Check your server's accessibility
5. Review the logs for specific error messages

---

**Happy Monitoring! 🎯📊**

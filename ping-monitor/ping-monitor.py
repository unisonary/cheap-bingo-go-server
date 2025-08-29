#!/usr/bin/env python3
"""
Bingo Server Ping Monitor
Self-hosted script to monitor Render.com service health
"""

import requests
import websocket
import json
import time
import datetime
import threading
import sys
import os
from urllib.parse import urlparse

class BingoServerMonitor:
    def __init__(self, base_url="https://cheap-bingo-go-server.onrender.com"):
        self.base_url = base_url.rstrip('/')
        self.ws_url = base_url.replace('https://', 'wss://').replace('http://', 'ws://') + '/ws'
        self.health_url = f"{self.base_url}/healthz"
        self.home_url = f"{self.base_url}/"
        
        # Statistics
        self.stats = {
            'http_checks': 0,
            'http_success': 0,
            'http_failures': 0,
            'ws_checks': 0,
            'ws_success': 0,
            'ws_failures': 0,
            'start_time': datetime.datetime.now(),
            'last_success': None,
            'last_failure': None
        }
        
        # Configuration
        self.check_interval = 120  # seconds (1 minute)
        self.timeout = 15  # seconds
        self.retry_count = 3
        self.alert_threshold = 3  # consecutive failures before alert
        
        # Status tracking
        self.consecutive_failures = 0
        self.is_running = False
        
    def log(self, message, level="INFO"):
        """Log message with timestamp"""
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {level}: {message}")
        
    def check_http_endpoint(self, url, name):
        """Check HTTP endpoint health"""
        try:
            response = requests.get(url, timeout=self.timeout)
            if response.status_code == 200:
                self.log(f"✅ {name} OK - Status: {response.status_code}", "SUCCESS")
                return True
            else:
                self.log(f"❌ {name} FAILED - Status: {response.status_code}", "ERROR")
                return False
        except requests.exceptions.RequestException as e:
            self.log(f"❌ {name} ERROR - {str(e)}", "ERROR")
            return False
            
    def check_websocket(self):
        """Check WebSocket connectivity"""
        try:
            # Create WebSocket connection with timeout
            ws = websocket.create_connection(self.ws_url, timeout=self.timeout)
            
            # Send a test message using a valid channel that the server handles
            test_message = {
                "channel": "create-room",
                "res": "monitor_test",
                "dimension": 5,
                "appVersion": "1.0.0"
            }
            
            ws.send(json.dumps(test_message))
            
            # Wait for response (or timeout)
            ws.settimeout(15)
            try:
                response = ws.recv()
                response_data = json.loads(response)
                if response_data.get("channel") == "create-room" and response_data.get("roomCode"):
                    self.log(f"✅ WebSocket OK - Room created: {response_data['roomCode']}", "SUCCESS")
                    ws.close()
                    return True
                else:
                    self.log(f"⚠️ WebSocket WARNING - Unexpected response: {response}", "WARNING")
                    ws.close()
                    return True  # Connection established, response received
            except websocket.WebSocketTimeoutException:
                self.log("⚠️ WebSocket TIMEOUT - No response received", "WARNING")
                ws.close()
                return True  # Connection established, just no response
                
        except Exception as e:
            self.log(f"❌ WebSocket ERROR - {str(e)}", "ERROR")
            return False
            
    def perform_health_check(self):
        """Perform complete health check"""
        self.log("🔍 Starting health check...", "INFO")
        
        # Check HTTP endpoints
        http_success = True
        
        # Check home page
        if not self.check_http_endpoint(self.home_url, "Home Page"):
            http_success = False
            
        # Check health endpoint
        if not self.check_http_endpoint(self.health_url, "Health Endpoint"):
            http_success = False
            
        # Check WebSocket
        ws_success = self.check_websocket()
        
        # Update statistics
        self.stats['http_checks'] += 1
        self.stats['ws_checks'] += 1
        
        if http_success:
            self.stats['http_success'] += 1
        else:
            self.stats['http_failures'] += 1
            
        if ws_success:
            self.stats['ws_success'] += 1
        else:
            self.stats['ws_failures'] += 1
            
        # Overall status
        overall_success = http_success and ws_success
        
        if overall_success:
            self.consecutive_failures = 0
            self.stats['last_success'] = datetime.datetime.now()
            self.log("🎉 Health check PASSED", "SUCCESS")
        else:
            self.consecutive_failures += 1
            self.stats['last_failure'] = datetime.datetime.now()
            self.log(f"💥 Health check FAILED (Consecutive failures: {self.consecutive_failures})", "ERROR")
            
            # Alert if threshold exceeded
            if self.consecutive_failures >= self.alert_threshold:
                self.send_alert()
                
        return overall_success
        
    def send_alert(self):
        """Send alert notification"""
        alert_msg = f"🚨 ALERT: Bingo server has failed {self.consecutive_failures} consecutive health checks!"
        alert_msg += f"\nServer: {self.base_url}"
        alert_msg += f"\nTime: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        
        self.log(alert_msg, "ALERT")
        
        # You can extend this to send emails, Slack messages, etc.
        # Example: send_slack_alert(alert_msg)
        # Example: send_email_alert(alert_msg)
        
    def print_stats(self):
        """Print current statistics"""
        uptime = datetime.datetime.now() - self.stats['start_time']
        
        print("\n" + "="*60)
        print("📊 BINGO SERVER MONITOR STATISTICS")
        print("="*60)
        print(f"Server URL: {self.base_url}")
        print(f"Monitor Uptime: {str(uptime).split('.')[0]}")
        print(f"Started: {self.stats['start_time'].strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # HTTP Stats
        http_total = self.stats['http_checks']
        if http_total > 0:
            http_success_rate = (self.stats['http_success'] / http_total) * 100
            print(f"HTTP Checks: {http_total}")
            print(f"HTTP Success: {self.stats['http_success']} ({http_success_rate:.1f}%)")
            print(f"HTTP Failures: {self.stats['http_failures']}")
        else:
            print("HTTP Checks: 0")
            
        print()
        
        # WebSocket Stats
        ws_total = self.stats['ws_checks']
        if ws_total > 0:
            ws_success_rate = (self.stats['ws_success'] / ws_total) * 100
            print(f"WebSocket Checks: {ws_total}")
            print(f"WebSocket Success: {self.stats['ws_success']} ({ws_success_rate:.1f}%)")
            print(f"WebSocket Failures: {self.stats['ws_failures']}")
        else:
            print("WebSocket Checks: 0")
            
        print()
        
        # Status
        if self.stats['last_success']:
            print(f"Last Success: {self.stats['last_success'].strftime('%Y-%m-%d %H:%M:%S')}")
        if self.stats['last_failure']:
            print(f"Last Failure: {self.stats['last_failure'].strftime('%Y-%m-%d %H:%M:%S')}")
            
        print(f"Consecutive Failures: {self.consecutive_failures}")
        print("="*60)
        
    def run_continuous_monitoring(self):
        """Run continuous monitoring"""
        self.is_running = True
        self.log("🚀 Starting continuous monitoring...", "INFO")
        self.log(f"Check interval: {self.check_interval} seconds", "INFO")
        self.log(f"Alert threshold: {self.alert_threshold} consecutive failures", "INFO")
        
        try:
            while self.is_running:
                self.perform_health_check()
                self.print_stats()
                
                # Wait for next check
                for i in range(self.check_interval, 0, -1):
                    if not self.is_running:
                        break
                    sys.stdout.write(f"\r⏳ Next check in {i} seconds... (Press Ctrl+C to stop)")
                    sys.stdout.flush()
                    time.sleep(1)
                    
                print()  # New line after countdown
                
        except KeyboardInterrupt:
            self.log("🛑 Monitoring stopped by user", "INFO")
        except Exception as e:
            self.log(f"💥 Monitoring error: {str(e)}", "ERROR")
        finally:
            self.is_running = False
            self.log("🏁 Monitoring stopped", "INFO")
            
    def run_single_check(self):
        """Run a single health check"""
        self.log("🔍 Running single health check...", "INFO")
        success = self.perform_health_check()
        self.print_stats()
        return success
        
    def test_websocket_connection(self):
        """Test WebSocket connection with detailed logging"""
        self.log("🔌 Testing WebSocket connection...", "INFO")
        
        try:
            # Parse URL
            parsed = urlparse(self.ws_url)
            self.log(f"Connecting to: {parsed.netloc}{parsed.path}", "INFO")
            
            # Create connection
            ws = websocket.create_connection(self.ws_url, timeout=self.timeout)
            self.log("✅ WebSocket connection established", "SUCCESS")
            
            # Test message using a valid channel
            test_message = {
                "channel": "create-room",
                "res": "monitor_test",
                "dimension": 5,
                "appVersion": "1.0.0"
            }
            
            self.log(f"Sending test message: {json.dumps(test_message)}", "INFO")
            ws.send(json.dumps(test_message))
            
            # Wait for response
            ws.settimeout(15)
            try:
                response = ws.recv()
                response_data = json.loads(response)
                if response_data.get("channel") == "create-room" and response_data.get("roomCode"):
                    self.log(f"✅ Response received: Room created with code: {response_data['roomCode']}", "SUCCESS")
                else:
                    self.log(f"⚠️ Unexpected response: {response}", "WARNING")
            except websocket.WebSocketTimeoutException:
                self.log("⚠️ No response received (timeout)", "WARNING")
                
            ws.close()
            self.log("✅ WebSocket test completed", "SUCCESS")
            
        except Exception as e:
            self.log(f"❌ WebSocket test failed: {str(e)}", "ERROR")

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Bingo Server Ping Monitor")
    parser.add_argument("--url", default="https://cheap-bingo-go-server.onrender.com",
                       help="Base URL of the Bingo server")
    parser.add_argument("--interval", type=int, default=60,
                        help="Check interval in seconds (default: 60)")
    parser.add_argument("--timeout", type=int, default=15,
                       help="Request timeout in seconds (default: 15)")
    parser.add_argument("--threshold", type=int, default=3,
                       help="Alert threshold for consecutive failures (default: 3)")
    parser.add_argument("--single", action="store_true",
                       help="Run single health check and exit")
    parser.add_argument("--test-ws", action="store_true",
                       help="Test WebSocket connection and exit")
    
    args = parser.parse_args()
    
    # Create monitor instance
    monitor = BingoServerMonitor(args.url)
    monitor.check_interval = args.interval
    monitor.timeout = args.timeout
    monitor.alert_threshold = args.threshold
    
    try:
        if args.test_ws:
            monitor.test_websocket_connection()
        elif args.single:
            success = monitor.run_single_check()
            sys.exit(0 if success else 1)
        else:
            monitor.run_continuous_monitoring()
            
    except KeyboardInterrupt:
        print("\n🛑 Exiting...")
        sys.exit(0)
    except Exception as e:
        print(f"💥 Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()

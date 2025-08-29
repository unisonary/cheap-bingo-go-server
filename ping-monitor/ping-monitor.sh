#!/bin/bash

# Bingo Server Ping Monitor - Shell Script
# This script provides easy access to the Python ping monitor

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/ping-monitor.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Check if Python 3 is available
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed or not in PATH"
        print_status "Please install Python 3.7+ and try again"
        exit 1
    fi
    
    # Check Python version
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    REQUIRED_VERSION="3.7"
    
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
        print_error "Python 3.7+ is required. Found: $PYTHON_VERSION"
        exit 1
    fi
    
    print_status "Python $PYTHON_VERSION found"
}

# Check if required packages are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! python3 -c "import requests, websocket" &> /dev/null; then
        print_warning "Required packages not found. Installing..."
        
        if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
            print_status "Installing from requirements.txt..."
            pip3 install -r "$SCRIPT_DIR/requirements.txt"
        else
            print_status "Installing required packages..."
            pip3 install requests websocket-client
        fi
        
        if [ $? -ne 0 ]; then
            print_error "Failed to install required packages"
            exit 1
        fi
        
        print_status "Dependencies installed successfully"
    else
        print_status "All dependencies are available"
    fi
}

# Show usage information
show_usage() {
    print_header "🎯 Bingo Server Ping Monitor"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -s, --single         Run single health check and exit"
    echo "  -w, --websocket      Test WebSocket connection only"
    echo "  -u, --url URL        Custom server URL (default: https://cheap-bingo-go-server.onrender.com)"
    echo "  -i, --interval SEC   Check interval in seconds (default: 30)"
    echo "  -t, --timeout SEC    Request timeout in seconds (default: 10)"
    echo "  -a, --alert NUM      Alert threshold for consecutive failures (default: 3)"
    echo
    echo "Examples:"
    echo "  $0                    # Start continuous monitoring"
    echo "  $0 -s                 # Run single health check"
    echo "  $0 -w                 # Test WebSocket connection"
    echo "  $0 -i 60              # Check every 60 seconds"
    echo "  $0 -u https://my-server.com  # Custom server URL"
    echo
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--single)
                MODE="single"
                shift
                ;;
            -w|--websocket)
                MODE="websocket"
                shift
                ;;
            -u|--url)
                SERVER_URL="$2"
                shift 2
                ;;
            -i|--interval)
                INTERVAL="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -a|--alert)
                ALERT_THRESHOLD="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set defaults
    MODE=${MODE:-"continuous"}
    SERVER_URL=${SERVER_URL:-"https://cheap-bingo-go-server.onrender.com"}
    INTERVAL=${INTERVAL:-30}
    TIMEOUT=${TIMEOUT:-10}
    ALERT_THRESHOLD=${ALERT_THRESHOLD:-3}
    
    # Check prerequisites
    check_python
    check_dependencies
    
    # Build command
    CMD="python3 $PYTHON_SCRIPT"
    
    case $MODE in
        "single")
            CMD="$CMD --single"
            print_status "Running single health check..."
            ;;
        "websocket")
            CMD="$CMD --test-ws"
            print_status "Testing WebSocket connection..."
            ;;
        "continuous")
            print_status "Starting continuous monitoring..."
            print_status "Server: $SERVER_URL"
            print_status "Interval: ${INTERVAL}s"
            print_status "Timeout: ${TIMEOUT}s"
            print_status "Alert threshold: $ALERT_THRESHOLD"
            echo
            ;;
    esac
    
    # Add custom parameters
    CMD="$CMD --url $SERVER_URL --interval $INTERVAL --timeout $TIMEOUT --threshold $ALERT_THRESHOLD"
    
    # Execute the command
    print_status "Executing: $CMD"
    echo
    eval $CMD
}

# Run main function with all arguments
main "$@"

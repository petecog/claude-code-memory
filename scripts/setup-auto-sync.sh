#!/bin/bash

# Claude Memory Auto-Sync Setup Script
# Sets up systemd service to automatically sync Claude memory

set -e

CLAUDE_DIR="/home/peter/.claude"
SERVICE_NAME="claude-memory-sync"
SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME.service"
MONITOR_SCRIPT="$CLAUDE_DIR/scripts/monitor-and-sync.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -d "$CLAUDE_DIR" ]]; then
        print_error "Claude directory not found: $CLAUDE_DIR"
        exit 1
    fi
    
    # Check if scripts exist
    if [[ ! -f "$MONITOR_SCRIPT" ]]; then
        print_error "Monitor script not found: $MONITOR_SCRIPT"
        exit 1
    fi
    
    # Check if this is a git repo
    if [[ ! -d "$CLAUDE_DIR/.git" ]]; then
        print_error "Not a git repository. Please run 'git init' first."
        exit 1
    fi
    
    # Check if systemd is available
    if ! command -v systemctl &> /dev/null; then
        print_error "systemctl not found. This script requires systemd."
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd user service..."
    
    # Create systemd user directory if it doesn't exist
    mkdir -p "$(dirname "$SERVICE_FILE")"
    
    # Create the service file
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Claude Memory Auto-Sync Monitor
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=$MONITOR_SCRIPT
Restart=always
RestartSec=10
StandardOutput=append:$CLAUDE_DIR/monitor.log
StandardError=append:$CLAUDE_DIR/monitor.log

# Environment
Environment=HOME=$HOME
Environment=USER=$USER

[Install]
WantedBy=default.target
EOF
    
    print_status "Service file created: $SERVICE_FILE"
}

# Function to enable and start service
enable_service() {
    print_status "Enabling and starting service..."
    
    # Reload systemd daemon
    systemctl --user daemon-reload
    
    # Enable service to start on login
    systemctl --user enable "$SERVICE_NAME"
    
    # Start service now
    systemctl --user start "$SERVICE_NAME"
    
    print_status "Service enabled and started"
}

# Function to show service status
show_status() {
    print_status "Service status:"
    echo
    systemctl --user status "$SERVICE_NAME" --no-pager
    echo
    
    print_status "To manage the service:"
    echo "  Start:   systemctl --user start $SERVICE_NAME"
    echo "  Stop:    systemctl --user stop $SERVICE_NAME"
    echo "  Restart: systemctl --user restart $SERVICE_NAME"
    echo "  Status:  systemctl --user status $SERVICE_NAME"
    echo "  Logs:    journalctl --user -u $SERVICE_NAME -f"
    echo
    echo "Log files:"
    echo "  Monitor: $CLAUDE_DIR/monitor.log"
    echo "  Sync:    $CLAUDE_DIR/sync.log"
}

# Function to uninstall service
uninstall_service() {
    print_warning "Uninstalling Claude memory auto-sync service..."
    
    # Stop and disable service
    systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
    systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
    
    # Remove service file
    rm -f "$SERVICE_FILE"
    
    # Reload daemon
    systemctl --user daemon-reload
    
    print_status "Service uninstalled"
}

# Main function
main() {
    case "${1:-install}" in
        "install")
            print_status "Installing Claude memory auto-sync service..."
            check_prerequisites
            create_systemd_service
            enable_service
            show_status
            print_status "Installation complete!"
            ;;
        "uninstall")
            uninstall_service
            ;;
        "status")
            show_status
            ;;
        "test")
            print_status "Testing service creation (dry run)..."
            check_prerequisites
            print_status "Would create service file: $SERVICE_FILE"
            print_status "Would monitor script: $MONITOR_SCRIPT"
            print_status "Test passed - ready for installation"
            ;;
        *)
            echo "Usage: $0 [install|uninstall|status|test]"
            echo "  install   - Install and start the auto-sync service (default)"
            echo "  uninstall - Remove the auto-sync service"
            echo "  status    - Show service status and management commands"
            echo "  test      - Test prerequisites without installing"
            exit 1
            ;;
    esac
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
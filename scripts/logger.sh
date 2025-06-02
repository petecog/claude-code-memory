#!/bin/bash

# Enhanced Logging System for Claude Memory
# Provides structured logging with rotation and status tracking

set -e

CLAUDE_DIR="/home/peter/.claude"
LOG_BASE_DIR="$CLAUDE_DIR/logs"
STATUS_TRACKER="$CLAUDE_DIR/scripts/status-tracker.sh"

# Create log directory structure
mkdir -p "$LOG_BASE_DIR"/{monitor,sync,merge}

# Function to get log file path with rotation
get_log_file() {
    local log_type="$1"
    local date_str=$(date '+%Y-%m')
    echo "$LOG_BASE_DIR/$log_type/$log_type-$date_str.log"
}

# Function to log with structured format
log_message() {
    local level="$1"
    local component="$2"
    local message="$3"
    local log_file="$4"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local machine=$(hostname)
    
    # Structured log entry
    echo "[$timestamp] [$level] [$component@$machine] $message" >> "$log_file"
    
    # Also output to stdout for immediate feedback
    echo "[$level] $message"
}

# Logging level functions
log_info() {
    local component="$1"
    local message="$2"
    local log_file="${3:-$(get_log_file "general")}"
    log_message "INFO" "$component" "$message" "$log_file"
}

log_warn() {
    local component="$1"
    local message="$2"
    local log_file="${3:-$(get_log_file "general")}"
    log_message "WARN" "$component" "$message" "$log_file"
}

log_error() {
    local component="$1"
    local message="$2"
    local log_file="${3:-$(get_log_file "general")}"
    log_message "ERROR" "$component" "$message" "$log_file"
    
    # Also update status tracker with error
    if [[ -x "$STATUS_TRACKER" ]]; then
        "$STATUS_TRACKER" error "$component" "$message"
    fi
}

log_success() {
    local component="$1"
    local message="$2"
    local log_file="${3:-$(get_log_file "general")}"
    log_message "SUCCESS" "$component" "$message" "$log_file"
}

# Function to start operation logging
start_operation() {
    local operation="$1"
    local log_type="${2:-sync}"
    local log_file=$(get_log_file "$log_type")
    
    log_info "$operation" "Starting operation" "$log_file"
    echo "$log_file"  # Return log file path for continued use
}

# Function to end operation logging with status update
end_operation() {
    local operation="$1"
    local status="$2"
    local log_file="$3"
    local changes=("${@:4}")
    
    if [[ "$status" == "success" ]]; then
        log_success "$operation" "Operation completed successfully" "$log_file"
    else
        log_error "$operation" "Operation failed: $status" "$log_file"
    fi
    
    # Update status tracker
    if [[ -x "$STATUS_TRACKER" ]]; then
        "$STATUS_TRACKER" update "$operation" "$status" "${changes[@]}"
    fi
}

# Function to rotate old logs
rotate_logs() {
    local days_old=${1:-30}
    
    find "$LOG_BASE_DIR" -name "*.log" -mtime +$days_old -exec gzip {} \;
    find "$LOG_BASE_DIR" -name "*.log.gz" -mtime +90 -delete
    
    log_info "log-rotation" "Rotated logs older than $days_old days"
}

# Function to get recent logs for troubleshooting
show_recent_logs() {
    local component="${1:-sync}"
    local lines="${2:-20}"
    local log_file=$(get_log_file "$component")
    
    if [[ -f "$log_file" ]]; then
        echo "=== Recent $component logs ==="
        tail -n "$lines" "$log_file"
    else
        echo "No recent logs found for $component"
    fi
}

# Main function for direct usage
main() {
    case "${1:-help}" in
        "info"|"warn"|"error"|"success")
            "log_$1" "$2" "$3" "$4"
            ;;
        "start")
            start_operation "$2" "$3"
            ;;
        "end")
            shift
            end_operation "$@"
            ;;
        "rotate")
            rotate_logs "$2"
            ;;
        "show")
            show_recent_logs "$2" "$3"
            ;;
        "status")
            if [[ -x "$STATUS_TRACKER" ]]; then
                "$STATUS_TRACKER" list
            fi
            ;;
        *)
            echo "Usage: $0 [info|warn|error|success|start|end|rotate|show|status]"
            echo "  info <component> <message> [logfile]     - Log info message"
            echo "  warn <component> <message> [logfile]     - Log warning message"
            echo "  error <component> <message> [logfile]    - Log error message"
            echo "  success <component> <message> [logfile]  - Log success message"
            echo "  start <operation> [log_type]             - Start operation logging"
            echo "  end <operation> <status> <logfile> [files...] - End operation with status"
            echo "  rotate [days]                            - Rotate old logs"
            echo "  show [component] [lines]                 - Show recent logs"
            echo "  status                                    - Show machine status summary"
            ;;
    esac
}

# Export functions for sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f log_info log_warn log_error log_success
    export -f start_operation end_operation
    export -f get_log_file rotate_logs show_recent_logs
else
    main "$@"
fi
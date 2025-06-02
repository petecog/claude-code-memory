#!/bin/bash

# Claude Memory Monitor Script
# Monitors Claude process and syncs memory when Claude exits

set -e

CLAUDE_DIR="/home/peter/.claude"
SYNC_SCRIPT="$CLAUDE_DIR/scripts/sync-memory.sh"
FLAG_FILE="/tmp/claude-was-running-$(whoami)"
LOGGER="$CLAUDE_DIR/scripts/logger.sh"

# Source logging functions
if [[ -f "$LOGGER" ]]; then
    source "$LOGGER"
    MONITOR_LOG=$(get_log_file "monitor")
else
    # Fallback logging
    MONITOR_LOG="$CLAUDE_DIR/monitor.log"
    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] MONITOR: $1" | tee -a "$MONITOR_LOG"; }
    log_info() { log "$2"; }
    log_warn() { log "$2"; }
    log_error() { log "$2"; }
fi

# Function to check if Claude is running
claude_running() {
    pgrep -f "claude" > /dev/null 2>&1
}

# Function to sync memory safely
trigger_sync() {
    log_info "monitor" "Claude session ended, triggering sync" "$MONITOR_LOG"
    
    if [[ -x "$SYNC_SCRIPT" ]]; then
        if "$SYNC_SCRIPT"; then
            log_success "monitor" "Sync completed successfully" "$MONITOR_LOG"
        else
            log_error "monitor" "Sync failed" "$MONITOR_LOG"
        fi
    else
        log_error "monitor" "Sync script not found or not executable: $SYNC_SCRIPT" "$MONITOR_LOG"
    fi
}

# Main monitoring loop
monitor_claude() {
    log_info "monitor" "Starting Claude memory monitor" "$MONITOR_LOG"
    
    while true; do
        if claude_running; then
            # Claude is running
            if [[ ! -f "$FLAG_FILE" ]]; then
                log_info "monitor" "Claude started" "$MONITOR_LOG"
                touch "$FLAG_FILE"
            fi
            
            # Wait longer while Claude is active
            sleep 60
            
        else
            # Claude is not running
            if [[ -f "$FLAG_FILE" ]]; then
                # Claude was running but now stopped
                rm "$FLAG_FILE"
                trigger_sync
            fi
            
            # Check more frequently when Claude not running
            sleep 10
        fi
    done
}

# Cleanup function for graceful shutdown
cleanup() {
    log_info "monitor" "Monitor stopping" "$MONITOR_LOG"
    [[ -f "$FLAG_FILE" ]] && rm "$FLAG_FILE"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Make sync script executable
chmod +x "$SYNC_SCRIPT" 2>/dev/null || true

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    monitor_claude
fi
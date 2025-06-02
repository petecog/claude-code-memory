#!/bin/bash

# Simple status tracker without complex JSON handling

CLAUDE_DIR="/home/peter/.claude"
STATUS_DIR="$CLAUDE_DIR/status"
MACHINE_NAME="$(hostname)"
STATUS_FILE="$STATUS_DIR/$MACHINE_NAME.json"

# Simple status update
update_status() {
    local operation="$1"
    local status="$2"
    shift 2
    local changes=("$@")
    
    mkdir -p "$STATUS_DIR"
    
    local timestamp=$(date -Iseconds)
    local sync_count=1
    
    # Simple sync count increment
    if [[ -f "$STATUS_FILE" ]] && grep -q sync_count "$STATUS_FILE"; then
        sync_count=$(grep '"sync_count"' "$STATUS_FILE" | grep -o '[0-9]*' | head -1)
        ((sync_count++))
    fi
    
    # Create simple status file
    cat > "$STATUS_FILE" << EOF
{
  "machine": "$MACHINE_NAME",
  "last_sync": "$timestamp",
  "last_operation": "$operation",
  "last_status": "$status",
  "last_changes": ["$(IFS='","'; echo "${changes[*]}")"],
  "sync_count": $sync_count,
  "machine_info": {
    "hostname": "$MACHINE_NAME",
    "user": "$(whoami)",
    "os": "$(uname -s)",
    "last_seen": "$timestamp"
  }
}
EOF
}

# Simple listing
list_status() {
    echo "=== Machine Status Summary ==="
    
    if [[ ! -d "$STATUS_DIR" ]]; then
        echo "No status directory found."
        return
    fi
    
    for status_file in "$STATUS_DIR"/*.json; do
        if [[ -f "$status_file" ]]; then
            local machine=$(basename "$status_file" .json)
            echo "Machine: $machine"
            if [[ -s "$status_file" ]]; then
                echo "  Status file exists and has content"
                head -3 "$status_file"
            else
                echo "  Status file is empty"
            fi
            echo
        fi
    done
}

case "${1:-list}" in
    "update")
        update_status "${@:2}"
        echo "Status updated for $MACHINE_NAME"
        ;;
    "list")
        list_status
        ;;
    *)
        echo "Usage: $0 [update|list]"
        ;;
esac
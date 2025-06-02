#!/bin/bash

# Claude Memory Sync Script
# Safely syncs Claude memory to GitHub repo

set -e  # Exit on any error

CLAUDE_DIR="/home/peter/.claude"
LOGGER="$CLAUDE_DIR/scripts/logger.sh"

# Source logging functions
if [[ -f "$LOGGER" ]]; then
    source "$LOGGER"
else
    # Fallback logging if logger not available
    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
    log_info() { log "INFO: $2"; }
    log_error() { log "ERROR: $2"; }
    log_warn() { log "WARN: $2"; }
    start_operation() { echo ""; }
    end_operation() { echo ""; }
fi

# Function to check if we're in a git repo
check_git_repo() {
    if [[ ! -d "$CLAUDE_DIR/.git" ]]; then
        log "ERROR: Not a git repository. Run git init first."
        exit 1
    fi
}

# Function to sync memory using machine-specific branches
sync_memory() {
    local log_file=$(start_operation "sync-memory" "sync")
    
    cd "$CLAUDE_DIR"
    
    # Check if there are any changes to sync
    if git diff --quiet && git diff --cached --quiet; then
        log_info "sync-memory" "No changes to sync" "$log_file"
        if [[ -x "$CLAUDE_DIR/scripts/status-tracker.sh" ]]; then
            "$CLAUDE_DIR/scripts/status-tracker.sh" update "sync-memory" "success"
        fi
        return 0
    fi
    
    # Determine machine branch name
    MACHINE_BRANCH="machine-$(hostname)"
    log_info "sync-memory" "Using machine branch: $MACHINE_BRANCH" "$log_file"
    
    # Get list of changed files for status tracking
    local changed_files
    changed_files=($(git diff --name-only HEAD))
    
    # Fetch latest remote state
    log_info "sync-memory" "Fetching latest remote state" "$log_file"
    git fetch origin
    
    # Switch to/create machine branch
    log_info "sync-memory" "Switching to machine branch" "$log_file"
    if git show-ref --verify --quiet refs/heads/$MACHINE_BRANCH; then
        # Branch exists locally, switch to it
        git checkout $MACHINE_BRANCH
    else
        # Create new branch from current state
        git checkout -b $MACHINE_BRANCH
    fi
    
    # Pull latest changes from our machine branch (if it exists remotely)
    log_info "sync-memory" "Syncing with remote machine branch" "$log_file"
    if git ls-remote --heads origin $MACHINE_BRANCH | grep -q $MACHINE_BRANCH; then
        if ! git pull origin $MACHINE_BRANCH; then
            log_warn "sync-memory" "Failed to pull from remote machine branch. Continuing..." "$log_file"
        fi
    fi
    
    # Also fetch latest main for reference (non-blocking)
    log_info "sync-memory" "Fetching main branch for reference" "$log_file"
    git fetch origin main:refs/remotes/origin/main 2>/dev/null || true
    
    # Stage all changes
    log_info "sync-memory" "Staging changes" "$log_file"
    git add .
    
    # Commit with timestamp and machine info
    log_info "sync-memory" "Committing changes" "$log_file"
    git commit -m "Auto-sync from $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')

Machine: $(hostname)
User: $(whoami)

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Push to machine branch
    log_info "sync-memory" "Pushing to machine branch" "$log_file"
    if git push -u origin $MACHINE_BRANCH; then
        log_success "sync-memory" "Sync completed successfully to $MACHINE_BRANCH" "$log_file"
        if [[ -x "$CLAUDE_DIR/scripts/status-tracker.sh" ]]; then
            "$CLAUDE_DIR/scripts/status-tracker.sh" update "sync-memory" "success" "${changed_files[@]}"
        fi
    else
        log_error "sync-memory" "Push failed. Changes committed locally to $MACHINE_BRANCH" "$log_file"
        if [[ -x "$CLAUDE_DIR/scripts/status-tracker.sh" ]]; then
            "$CLAUDE_DIR/scripts/status-tracker.sh" update "sync-memory" "push_failed" "${changed_files[@]}"
        fi
        exit 1
    fi
}

# Main execution
main() {
    check_git_repo
    sync_memory
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
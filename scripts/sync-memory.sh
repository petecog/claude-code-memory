#!/bin/bash

# Claude Memory Sync Script
# Safely syncs Claude memory to GitHub repo

set -e  # Exit on any error

CLAUDE_DIR="/home/peter/.claude"
LOG_FILE="$CLAUDE_DIR/sync.log"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if we're in a git repo
check_git_repo() {
    if [[ ! -d "$CLAUDE_DIR/.git" ]]; then
        log "ERROR: Not a git repository. Run git init first."
        exit 1
    fi
}

# Function to sync memory using machine-specific branches
sync_memory() {
    log "Starting Claude memory sync..."
    
    cd "$CLAUDE_DIR"
    
    # Check if there are any changes to sync
    if git diff --quiet && git diff --cached --quiet; then
        log "No changes to sync."
        return 0
    fi
    
    # Determine machine branch name
    MACHINE_BRANCH="machine-$(hostname)"
    log "Using machine branch: $MACHINE_BRANCH"
    
    # Fetch latest remote state
    log "Fetching latest remote state..."
    git fetch origin
    
    # Switch to/create machine branch
    log "Switching to machine branch..."
    if git show-ref --verify --quiet refs/heads/$MACHINE_BRANCH; then
        # Branch exists locally, switch to it
        git checkout $MACHINE_BRANCH
    else
        # Create new branch from current state
        git checkout -b $MACHINE_BRANCH
    fi
    
    # Pull latest changes from our machine branch (if it exists remotely)
    log "Syncing with remote machine branch..."
    if git ls-remote --heads origin $MACHINE_BRANCH | grep -q $MACHINE_BRANCH; then
        if ! git pull origin $MACHINE_BRANCH; then
            log "WARNING: Failed to pull from remote machine branch. Continuing..."
        fi
    fi
    
    # Also fetch latest main for reference (non-blocking)
    log "Fetching main branch for reference..."
    git fetch origin main:refs/remotes/origin/main 2>/dev/null || true
    
    # Stage all changes
    log "Staging changes..."
    git add .
    
    # Commit with timestamp and machine info
    log "Committing changes..."
    git commit -m "Auto-sync from $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')

Machine: $(hostname)
User: $(whoami)

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Push to machine branch
    log "Pushing to machine branch..."
    if git push -u origin $MACHINE_BRANCH; then
        log "Sync completed successfully to $MACHINE_BRANCH."
    else
        log "ERROR: Push failed. Changes committed locally to $MACHINE_BRANCH."
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
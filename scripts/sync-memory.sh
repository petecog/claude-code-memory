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

# Function to sync memory
sync_memory() {
    log "Starting Claude memory sync..."
    
    cd "$CLAUDE_DIR"
    
    # Check if there are any changes to sync
    if git diff --quiet && git diff --cached --quiet; then
        log "No changes to sync."
        return 0
    fi
    
    # Pull latest changes first (in case of updates from other machines)
    log "Pulling latest changes..."
    if ! git pull --rebase origin main 2>/dev/null; then
        log "WARNING: Pull failed. Proceeding with local changes only."
    fi
    
    # Stage all changes
    log "Staging changes..."
    git add .
    
    # Commit with timestamp
    log "Committing changes..."
    git commit -m "Auto-sync Claude memory - $(date '+%Y-%m-%d %H:%M:%S')

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Push to remote
    log "Pushing to remote..."
    if git push origin main; then
        log "Sync completed successfully."
    else
        log "ERROR: Push failed. Changes committed locally."
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
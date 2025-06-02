#!/bin/bash

# Claude Memory Merge Script
# Merges machine-specific branches into main branch

set -e

CLAUDE_DIR="/home/peter/.claude"
LOG_FILE="$CLAUDE_DIR/merge.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}" | tee -a "$LOG_FILE"
}

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] MERGE: $1" >> "$LOG_FILE"
}

# Function to list machine branches
list_machine_branches() {
    print_section "Available Machine Branches"
    
    git fetch origin --prune
    
    local branches
    branches=$(git branch -r | grep 'origin/machine-' | sed 's|origin/||' | sed 's|^[[:space:]]*||' || true)
    
    if [[ -z "$branches" ]]; then
        print_warning "No machine branches found"
        return 1
    fi
    
    echo "Machine branches with last activity:"
    for branch in $branches; do
        local last_commit
        last_commit=$(git log -1 --format="%cr by %an" "origin/$branch" 2>/dev/null || echo "unknown")
        printf "  %-20s %s\n" "$branch" "$last_commit"
    done
    
    # Return branches as newline-separated for proper parsing
    echo "$branches" | tr ' ' '\n'
}

# Function to preview merge conflicts
preview_merge() {
    local branch="$1"
    print_section "Preview merge of $branch"
    
    # Create temporary branch for preview
    local preview_branch="preview-merge-$(date +%s)"
    git checkout main
    git checkout -b "$preview_branch"
    
    if git merge --no-commit --no-ff "origin/$branch" 2>/dev/null; then
        print_status "✓ $branch can be merged cleanly"
        git merge --abort 2>/dev/null || true
    else
        print_warning "⚠ $branch has conflicts:"
        git status --porcelain | grep '^UU\|^AA\|^DD' | while read -r status file; do
            echo "    CONFLICT: $file"
        done
        git merge --abort 2>/dev/null || true
    fi
    
    # Cleanup preview branch
    git checkout main
    git branch -D "$preview_branch" 2>/dev/null || true
}

# Function to auto-resolve safe files
auto_resolve_file() {
    local file="$1"
    
    case "$file" in
        ".claude/memory/"*)
            # Memory files: keep both versions with machine prefix
            print_status "Auto-resolving memory file: $file"
            return 0
            ;;
        ".claude/decisions.md")
            # Decisions: append both versions
            print_status "Auto-resolving decisions.md (append both)"
            return 0
            ;;
        "monitor.log"|"sync.log"|"merge.log")
            # Log files: ignore conflicts, keep ours
            print_status "Auto-resolving log file: $file (keeping main)"
            git checkout --ours "$file"
            git add "$file"
            return 0
            ;;
        "ide/"*)
            # IDE files: take newest
            print_status "Auto-resolving IDE file: $file (taking newer)"
            git checkout --theirs "$file"
            git add "$file"
            return 0
            ;;
    esac
    
    return 1
}

# Function to merge specific branch
merge_branch() {
    local branch="$1"
    local auto_resolve="${2:-false}"
    
    print_section "Merging $branch into main"
    
    # Ensure we're on main and up to date
    git checkout main
    git pull origin main
    
    # Attempt merge
    if git merge --no-ff "origin/$branch" -m "Merge $branch into main

Merged changes from $(echo "$branch" | sed 's/machine-//') machine.

$(date '+%Y-%m-%d %H:%M:%S')"; then
        print_status "✓ $branch merged successfully"
        return 0
    fi
    
    # Handle conflicts
    print_warning "Merge conflicts detected in $branch"
    
    local conflicted_files
    conflicted_files=$(git status --porcelain | grep '^UU\|^AA\|^DD' | cut -c4-)
    
    if [[ "$auto_resolve" == "true" ]]; then
        print_status "Attempting auto-resolution..."
        
        local resolved=true
        for file in $conflicted_files; do
            if ! auto_resolve_file "$file"; then
                print_warning "Cannot auto-resolve: $file"
                resolved=false
            fi
        done
        
        if [[ "$resolved" == "true" ]]; then
            git commit -m "Auto-resolved merge conflicts for $branch"
            print_status "✓ All conflicts auto-resolved"
            return 0
        fi
    fi
    
    # Manual intervention needed
    print_error "Manual resolution required for $branch"
    echo "Conflicted files:"
    for file in $conflicted_files; do
        echo "  - $file"
    done
    echo
    echo "To resolve manually:"
    echo "  1. Edit conflicted files"
    echo "  2. git add <resolved-files>"
    echo "  3. git commit"
    echo "  4. Re-run this script"
    echo
    echo "To abort this merge:"
    echo "  git merge --abort"
    
    return 1
}

# Function to interactive merge
interactive_merge() {
    local branches="$1"
    
    print_section "Interactive Merge Mode"
    
    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        echo
        print_status "Process branch: $branch"
        preview_merge "$branch"
        
        echo "Options:"
        echo "  1) Merge with auto-resolve"
        echo "  2) Merge manually (will stop on conflicts)"
        echo "  3) Skip this branch"
        echo "  4) Quit"
        
        read -p "Choose [1-4]: " choice
        case $choice in
            1)
                if merge_branch "$branch" true; then
                    print_status "✓ Merged $branch successfully"
                else
                    print_error "Failed to merge $branch"
                    return 1
                fi
                ;;
            2)
                merge_branch "$branch" false
                ;;
            3)
                print_warning "Skipping $branch"
                ;;
            4)
                print_status "Exiting interactive merge"
                return 0
                ;;
            *)
                print_warning "Invalid choice, skipping $branch"
                ;;
        esac
    done <<< "$branches"
}

# Main function
main() {
    cd "$CLAUDE_DIR"
    
    log "Starting merge operation"
    
    case "${1:-interactive}" in
        "list")
            list_machine_branches
            ;;
        "preview")
            branches=$(list_machine_branches)
            while IFS= read -r branch; do
                [[ -z "$branch" ]] && continue
                preview_merge "$branch"
            done <<< "$branches"
            ;;
        "auto")
            branches=$(list_machine_branches)
            print_section "Auto-merge mode"
            while IFS= read -r branch; do
                [[ -z "$branch" ]] && continue
                if merge_branch "$branch" true; then
                    print_status "✓ Auto-merged $branch"
                else
                    print_error "Failed to auto-merge $branch"
                    exit 1
                fi
            done <<< "$branches"
            print_status "Pushing merged main branch..."
            git push origin main
            ;;
        "interactive")
            branches=$(list_machine_branches)
            interactive_merge "$branches"
            
            echo
            read -p "Push merged main branch to origin? [y/N]: " push_choice
            if [[ "$push_choice" =~ ^[Yy]$ ]]; then
                print_status "Pushing main branch..."
                git push origin main
            fi
            ;;
        *)
            echo "Usage: $0 [list|preview|auto|interactive]"
            echo "  list        - List all machine branches"
            echo "  preview     - Preview merge conflicts"
            echo "  auto        - Auto-merge all branches"
            echo "  interactive - Interactive merge process (default)"
            exit 1
            ;;
    esac
    
    log "Merge operation completed"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
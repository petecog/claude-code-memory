# Sync Script Debugging and Fixes - June 2, 2025

## Issue Discovered
User reported that `scripts/sync-memory.sh` was failing with error:
```
[INFO] Starting operation
/home/peter/.claude/logs/sync/sync-2025-06.log: No such file or directory
```

## Root Cause Analysis
Found two distinct but related issues:

### 1. Logger Output Interference
- The `start_operation` function in `logger.sh` was returning multiple values
- It echoed both the log message AND the log file path to stdout
- When `sync-memory.sh` captured this with command substitution, it got a multi-line string
- This corrupted the `log_file` variable, causing subsequent logging to fail

### 2. Perpetual Git Conflicts
- Status files (`status/pop-os.json`) were being tracked by git
- These files get updated during sync operations
- This created a chicken-and-egg problem: every sync created changes that blocked the next sync

## Solutions Implemented

### Fix 1: Logger Output Redirection
**File**: `scripts/logger.sh:36`
**Change**: Redirected immediate feedback messages to stderr instead of stdout
```bash
# Before
echo "[$level] $message"

# After  
echo "[$level] $message" >&2
```
**Result**: Only the log file path is returned from `start_operation`, preventing corruption

### Fix 2: Exclude Status Files from Git
**Files**: `.gitignore`, removed `status/` from tracking
**Changes**:
- Added `status/` to `.gitignore`
- Removed status files from git index with `git rm --cached -r status/`
- Status files remain local to each machine for operational tracking

## Testing Results
- Script now runs successfully without errors
- Multiple consecutive runs work without git conflicts
- Status tracking continues to function locally
- Logging system works correctly with proper output separation

## Files Modified
1. `scripts/logger.sh` - Fixed output redirection
2. `.gitignore` - Added status/ exclusion
3. Removed from git: `status/README.md`, `status/pop-os.json`

## Commits Made
1. `a7710c3` - Fix logger output redirection
2. `ee96dfd` - Update machine status after sync operations  
3. `fe87bd5` - Exclude machine status files from git tracking
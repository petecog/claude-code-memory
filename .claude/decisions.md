# Claude Memory System Design Decisions

## Git Repository Structure
- **Decision**: Use private GitHub repo to sync Claude memory across machines
- **Rationale**: Enables recovery of Claude context and preferences on new machines
- **Date**: 2025-02-06

## What to Track in Git
- **Include**: CLAUDE.md (global preferences), .claude/ subdirectory structure, decisions.md, ide/ (session metadata)
- **Exclude**: Conversation logs, cache files, transient session data
- **Rationale**: Keep preferences and structure while excluding sensitive/transient data

## Directory Analysis & Inclusion Decisions
- **Date**: 2025-02-06

### Included Directories:
- `ide/` - Contains only IDE session metadata (PID, workspace, transport) - not sensitive
- `memory/` - Global memory files for cross-machine sync (user preference)

### Excluded Directories:
- `projects/` - Full conversation logs with detailed project discussions - stay local, get summarized in project repos
- `statsig/` - Analytics/telemetry cache with user IDs and session data - privacy concern
- `todos/` - Session-specific todo cache files - transient data
- `input/` - User file sharing area - transient and potentially sensitive
- `scratch/` - Experimental/temporary work - not for syncing

## Memory Strategy
- **Decision**: Store decisions and summaries in project repos, not raw conversation logs
- **Rationale**: Distilled knowledge is portable, raw logs are working data
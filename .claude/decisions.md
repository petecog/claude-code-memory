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

## Automation Implementation
- **Decision**: Use systemd user service with process monitoring for auto-sync
- **Rationale**: Most reliable approach - no Claude Code integration available, systemd handles lifecycle properly
- **Date**: 2025-02-06

## Final Architecture
- **Decision**: Self-contained automation with portable deployment script
- **Implementation**: Monitor script detects Claude exit → triggers git sync → logs to files
- **Benefits**: Zero-maintenance, cross-machine portable, privacy-conscious
- **Date**: 2025-02-06

## Conflict Resolution Strategy
- **Decision**: Machine-specific branches with assisted merge to main
- **Rationale**: Eliminates daily sync conflicts while maintaining clean main branch
- **Implementation**: Each machine pushes to `machine-hostname` branch, periodic merge via script
- **Benefits**: Zero conflicts in auto-sync, complete change history, manual merge control
- **Date**: 2025-02-06

## Merge Automation Features
- **Decision**: Multi-mode merge script with smart conflict resolution
- **Modes**: List, preview, auto-merge, interactive
- **Auto-resolution rules**: File-type specific strategies (memory files, decisions, logs, IDE files)
- **Manual control**: Interactive mode for complex conflicts
- **Date**: 2025-02-06

## Enhanced Logging System
- **Decision**: Exclude operational logs from git, sync status summaries only
- **Rationale**: Eliminate log-based conflicts while maintaining cross-machine visibility
- **Implementation**: Local logs in `logs/` (excluded), status summaries in `status/` (synced)
- **Benefits**: Clean repository, debugging capability, cross-machine awareness
- **Date**: 2025-02-06

## Status Tracking Architecture
- **Decision**: Simple JSON status files without complex dependencies
- **Structure**: Per-machine status files with sync metrics and machine info
- **Location**: Root-level `status/` directory for easy access
- **Content**: Last sync time, operation status, file counts, machine metadata
- **Date**: 2025-02-06
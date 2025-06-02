# Status Tracking System

This directory contains machine status summaries that are synced across machines.

## Files
- `{hostname}.json` - Status for each machine with sync history
- `README.md` - This documentation

## Status File Format
```json
{
  "machine": "hostname",
  "last_sync": "2025-02-06T13:50:30Z",
  "last_operation": "sync-memory",
  "last_status": "success",
  "last_changes": ["README.md", "decisions.md"],
  "sync_count": 15,
  "machine_info": {
    "hostname": "hostname",
    "user": "username",
    "os": "Linux",
    "last_seen": "2025-02-06T13:50:30Z"
  }
}
```

## Commands
```bash
# View all machine statuses
./scripts/status-tracker.sh list

# View recent logs
./scripts/logger.sh show sync 20

# Show status for this machine
cat status/$(hostname).json
```

## Cross-Machine Visibility

Each machine automatically updates its status file when syncing. This provides:
- **Last sync time** for each machine
- **Operation status** (success/failure)  
- **File change counts** per sync
- **Machine information** (OS, user, etc.)

Status files are small JSON files that sync cleanly across machines without conflicts.
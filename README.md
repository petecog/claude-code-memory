# Claude Memory System

Automated Claude Code memory management with cross-machine synchronization.

## Features

🤖 **Auto-sync on Claude exit** - No manual intervention required  
🔄 **Cross-machine portable** - Clone and deploy anywhere  
🔒 **Privacy-conscious** - Excludes conversation logs, includes only preferences  
⚙️ **Self-contained** - Background service handles everything  
📝 **Smart logging** - Monitor and sync activity tracked  

## Quick Setup

### New Machine Setup
```bash
# Clone this repo to ~/.claude
git clone git@github.com:petecog/claude-code-memory.git ~/.claude
cd ~/.claude

# Install auto-sync service
./scripts/setup-auto-sync.sh install
```

### Management Commands
```bash
# Check service status
./scripts/setup-auto-sync.sh status

# Manual sync (if needed)
./scripts/sync-memory.sh

# Merge machine branches to main
./scripts/merge-to-main.sh list        # List all machine branches
./scripts/merge-to-main.sh auto        # Auto-merge all branches  
./scripts/merge-to-main.sh interactive # Interactive merge process

# Uninstall auto-sync
./scripts/setup-auto-sync.sh uninstall
```

## How It Works

1. **Background Monitor**: Systemd service watches for Claude Code process
2. **Exit Detection**: When Claude exits, sync is automatically triggered  
3. **Machine-Branch Sync**: Each machine pushes to its own branch (machine-hostname)
4. **Conflict-Free**: No merge conflicts in daily auto-sync
5. **Manual Merge**: Periodic merge to main branch using assisted merge script

## What Gets Synced

### ✅ Included
- `CLAUDE.md` - Global Claude preferences
- `.claude/` - Memory structure and decisions  
- `ide/` - Session metadata (non-sensitive)
- `memory/` - Cross-machine context

### ❌ Excluded  
- `projects/` - Full conversation logs (stay local)
- `statsig/` - Analytics data (privacy)
- `todos/` - Session cache (transient)
- `input/` - File sharing area (transient)
- `scratch/` - Experimental work

## Repository Structure

```
~/.claude/                      # Git repo root
├── README.md                   # This file
├── CLAUDE.md                   # Global Claude preferences
├── .gitignore                  # Smart exclusions
├── .claude/                    # Memory organization
│   ├── decisions.md            # Key design decisions
│   ├── memory/                 # Session summaries
│   ├── input/                  # File sharing (excluded)
│   └── scratch/                # Experiments (excluded)
├── scripts/                    # Automation
│   ├── setup-auto-sync.sh      # Service deployment
│   ├── monitor-and-sync.sh     # Process monitoring
│   ├── sync-memory.sh          # Machine-branch sync
│   ├── merge-to-main.sh        # Branch merge assistance
│   ├── logger.sh               # Enhanced logging system
│   └── status-tracker.sh       # Cross-machine status tracking
├── status/                     # Cross-machine status summaries (synced)
│   ├── README.md               # Status system documentation
│   └── {hostname}.json         # Status file per machine
├── logs/                       # Local operational logs (excluded)
└── ide/                        # Session metadata (included)
```

## Branch Structure

```
GitHub Repo:
├── main                        # Clean, manually curated branch
├── machine-hostname1           # Auto-sync from machine 1
├── machine-hostname2           # Auto-sync from machine 2  
└── machine-hostname3           # Auto-sync from machine 3
```

## Logs and Status

### Local Logs (Excluded from Git)
- **Structured logs**: `logs/{component}/{component}-YYYY-MM.log`
- **Recent logs**: `./scripts/logger.sh show sync 20`
- **System service**: `journalctl --user -u claude-memory-sync -f`

### Cross-Machine Status (Synced)  
- **All machines**: `./scripts/status-tracker.sh list`
- **This machine**: `cat status/$(hostname).json`
- **Status directory**: `status/` contains JSON summaries for each machine

## Troubleshooting

### Service not starting
```bash
# Check service status
systemctl --user status claude-memory-sync

# View logs
journalctl --user -u claude-memory-sync -f
```

### Sync failures
```bash
# Check sync log
tail -f ~/.claude/sync.log

# Manual sync to test
./scripts/sync-memory.sh
```

### Machine branch conflicts
Machine branches avoid conflicts by design. If issues occur:
1. Check `sync.log` for sync errors on the specific machine
2. Use `./scripts/merge-to-main.sh list` to see branch status
3. Merge branches manually: `./scripts/merge-to-main.sh interactive`

### Merge conflicts in main
When merging machine branches to main:
1. Use `./scripts/merge-to-main.sh preview` to see conflicts
2. Auto-resolve with `./scripts/merge-to-main.sh auto` 
3. Or use interactive mode for manual control

## Requirements

- Linux with systemd (user services)
- Git with SSH key configured for GitHub
- Claude Code installed and running
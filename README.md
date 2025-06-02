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

# Uninstall auto-sync
./scripts/setup-auto-sync.sh uninstall
```

## How It Works

1. **Background Monitor**: Systemd service watches for Claude Code process
2. **Exit Detection**: When Claude exits, sync is automatically triggered  
3. **Git Sync**: Pull latest → commit changes → push to GitHub
4. **Conflict Handling**: Smart rebase strategy with error logging

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
│   └── sync-memory.sh          # Git operations
└── ide/                        # Session metadata (included)
```

## Logs

- **Monitor activity**: `~/.claude/monitor.log`
- **Sync operations**: `~/.claude/sync.log`  
- **System service**: `journalctl --user -u claude-memory-sync -f`

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

### Git conflicts
Auto-sync uses rebase strategy to handle conflicts. If sync fails:
1. Check `sync.log` for details
2. Resolve conflicts manually in the repo
3. Service will retry on next Claude exit

## Requirements

- Linux with systemd (user services)
- Git with SSH key configured for GitHub
- Claude Code installed and running
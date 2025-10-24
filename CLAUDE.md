# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Manual Backup Execution
```bash
# Run backup manually
./backup.sh

# Check logs
tail -f ~/logs/macbackups.log
```

### Service Management
```bash
# Load service
launchctl load ~/Library/LaunchAgents/com.user.macbackups.plist

# Start service
launchctl start com.user.macbackups

# Stop service
launchctl stop com.user.macbackups

# Unload service (for configuration changes)
launchctl unload ~/Library/LaunchAgents/com.user.macbackups.plist

# Check service status
launchctl list | grep macbackups
```

### Setup Commands
```bash
# Make script executable
chmod +x backup.sh

# Create required directories
mkdir -p "$HOME/Documents/MacBackups"
mkdir -p "$HOME/logs"

# Copy backup items template to home directory
cp macbackups-items.txt ~/.macbackups-items.txt
```

## Architecture

### Core Components
- **backup.sh**: Main backup script using RSYNC for incremental synchronization
- **backup.conf**: Configuration file with paths and settings
- **macbackups-items.txt**: List of files/directories to backup (one per line)
- **com.user.macbackups.plist**: launchd service definition for automated hourly backups

### How It Works
1. **Configuration Loading**: Script sources backup.conf to get paths and settings
2. **Directory Validation**: Checks source directory exists, creates destination if needed
3. **Exclusion Setup**: Creates default exclusion file for system/temporary files
4. **Item Processing**: Reads backup items from macbackups-items.txt and processes each with RSYNC
5. **Logging**: Detailed logging with timestamps and automatic log rotation

### Key Design Patterns
- **Modular Configuration**: All paths and settings centralized in backup.conf
- **File-based Item Selection**: Uses gitignore-style syntax in macbackups-items.txt
- **Automatic Exclusions**: Creates sensible defaults for macOS system files
- **Incremental Backups**: RSYNC's --delete option maintains mirror while only transferring changes

### Service Integration
The launchd service runs hourly with:
- Low priority I/O and Nice value of 10 to minimize impact
- Separate stdout/stderr logging for debugging
- RunAtLoad for immediate first backup
- Working directory set to script location

### File Locations
- **Backup Items**: `~/.macbackups-items.txt` (user-specific)
- **Exclusions**: `~/.macbackups-exclude.txt` (auto-generated)
- **Logs**: `~/logs/macbackups.log` (main log), plus stdout/stderr logs
- **Destination**: `~/Documents/MacBackups` (default, configurable)

### Error Handling
- Script exits on configuration errors
- Continues processing other items if individual backup fails
- Tracks and reports success/error counts
- Comprehensive logging for troubleshooting
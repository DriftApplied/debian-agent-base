# Debian Agent Base

A personal post-install automation system for Debian Stable.

## Current Status (as of 2026-05-25)

### Fully Implemented
- **Base layer** (`base.sh`)
  - System updates + essential packages
  - `lm-sensors` with automatic non-interactive configuration
  - Dark console theme + shell improvements
  - SSH server enabled

- **nvm + Kilo CLI** (`nvm-kilo.sh`)
  - nvm installation
  - Latest Node LTS
  - Kilo CLI installed globally
  - Automatic nvm loading in future shells

- **tmux** (`tmux.sh`)
  - Practical configuration for long-running agent sessions
  - High scrollback
  - Easy session sharing (SSH + local console)
  - `tmux-main` alias

- **LXQt Desktop** (`desktop-lxqt.sh`)
  - Minimal LXQt installation (avoids full desktop task)
  - Aggressive removal of bloat (LibreOffice, etc.)
  - SDDM as display manager
  - Dark theme applied (Breeze Dark + Qt settings)

### Main Installer
- `install.sh` with three modes:
  - `./install.sh` → Base + nvm + Kilo + tmux
  - `./install.sh --desktop` → Above + debloated LXQt
  - `./install.sh --full` → Prepared for future additions

## Usage

On a fresh minimal Debian Stable netinst:

```bash
./install.sh              # Base + nvm + Kilo + tmux
./install.sh --desktop    # Full desktop experience (LXQt)
```

After running, **log out and back in** (or reboot) for all changes to take effect.

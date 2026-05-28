# Debian Agent Base

A personal post-install automation system for Debian Stable.

## Current Status (as of 2026-05-26)

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

- **Network Manager** (`network.sh`)
  - Lightweight NetworkManager (core packages)
  - Automatic USB wifi adapter detection
  - CLI network selector (`nm-select` command)
  - `nml`/`nma`/`nmc` aliases for quick access

- **LXQt Desktop** (`desktop-lxqt.sh`)
  - Minimal LXQt installation (avoids full desktop task)
  - Aggressive removal of bloat (LibreOffice, etc.)
  - LightDM as display manager
  - Dark theme applied (Breeze Dark + Qt settings)

### Main Installer
- `install.sh` with three modes:
  - `./install.sh` → Base + Network + nvm + Kilo + tmux
  - `./install.sh --desktop` → Above + debloated LXQt + Firefox
  - `./install.sh --full` → All of the above + future additions

## Usage

On a fresh minimal Debian Stable netinst:

```bash
./install.sh              # Base + Network + nvm + Kilo + tmux
./install.sh --desktop    # Full desktop experience (LXQt + Firefox + Network Manager applet)
```

After running, **log out and back in** (or reboot) for all changes to take effect.

## Network Manager Usage

After installation, connect to wifi networks:

```bash
nm-select     # Interactive menu to select and connect to a network
nml           # List all available wifi networks
nmc           # Show all saved connections
nma           # Show active connections
```

On the desktop, click the network icon in the system tray to manage connections.

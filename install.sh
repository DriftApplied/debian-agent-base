#!/usr/bin/env bash
#
# Debian Agent Base - Main Installer
# https://github.com/DriftApplied (personal use)
#
# Usage:
#   ./install.sh              # Base only
#   ./install.sh --desktop    # Base + LXQt
#   ./install.sh --full       # Base + Desktop + future additions
#

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# =============================================================================
# Logging
# =============================================================================
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
}

# =============================================================================
# Argument Parsing
# =============================================================================
MODE="base"

while [[ $# -gt 0 ]]; do
    case $1 in
        --desktop)
            MODE="desktop"
            shift
            ;;
        --full)
            MODE="full"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--desktop | --full]"
            echo ""
            echo "  (no flag)   Install base only (recommended)"
            echo "  --desktop   Install base + LXQt desktop"
            echo "  --full      Install base + desktop + future additions"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

log "Starting Debian Agent Base installer"
log "Mode: $MODE"

# =============================================================================
# Source Libraries
# =============================================================================
source "${LIB_DIR}/utils.sh"

# =============================================================================
# Main Execution
# =============================================================================

# Always run base
log "=== Running Base Setup ==="
source "${LIB_DIR}/base.sh"

# Network manager (essential for wifi connectivity)
log "=== Running Network Manager Setup ==="
source "${LIB_DIR}/network.sh"

# nvm + Kilo CLI (core requirement)
log "=== Running nvm + Kilo CLI Setup ==="
source "${LIB_DIR}/nvm-kilo.sh"

# tmux (highly recommended for this workflow)
log "=== Running tmux Setup ==="
source "${LIB_DIR}/tmux.sh"

# Desktop layers
if [[ "$MODE" == "desktop" || "$MODE" == "full" ]]; then
    log "=== Running LXQt Desktop Setup ==="
    source "${LIB_DIR}/desktop-lxqt.sh"

    log "=== Running Browser Setup ==="
    source "${LIB_DIR}/browser.sh"
fi

# Future full mode additions can go here
if [[ "$MODE" == "full" ]]; then
    log "=== Running Full Mode Additions ==="
    # Add future modules here
fi

log "=== Installation Complete ==="
log "You may want to log out and back in (or reboot) for all changes to take effect."

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

# Source utilities early so we can use logging functions
source "${LIB_DIR}/utils.sh"

# =============================================================================
# Argument Parsing
# =============================================================================
MODE="base"
DRY_RUN=false

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
        --dry-run|--test)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--desktop | --full] [--dry-run|--test]"
            echo ""
            echo "  (no flag)   Install base only (recommended)"
            echo "  --desktop   Install base + LXQt desktop"
            echo "  --full      Install base + desktop + future additions"
            echo "  --dry-run   Show what would be done without making changes"
            echo "  --test      Alias for --dry-run"
            echo ""
            echo "Examples:"
            echo "  $0                  # Base installation"
            echo "  $0 --desktop        # Base + LXQt desktop"
            echo "  $0 --full           # Base + desktop + future additions"
            echo "  $0 --dry-run        # See what would be installed"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

ERROR_OCCURRED=0
trap 'ERROR_OCCURRED=1' ERR

report_status() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log "=== Dry run complete: no changes were made ==="
        log "Re-run without --dry-run to perform the installation and reboot afterward."
        return
    fi

    if [[ "$ERROR_OCCURRED" -eq 0 ]]; then
        log "=== Installation completed successfully ==="
    else
        log "=== Installation encountered errors (see logs above) ==="
    fi
    log "Please reboot or log out/in to ensure all changes take effect."
}

trap 'report_status' EXIT

log "Starting Debian Agent Base installer"
log "Mode: $MODE"

# =============================================================================
# Main Execution
# =============================================================================

# Always run hardware detection first (helps inform other steps)
if [[ "$DRY_RUN" == true ]]; then
    log "[DRY-RUN] Would execute: Hardware Detection"
    log "[DRY-RUN] Command: source \"${LIB_DIR}/hardware-detect.sh\""
else
    log "=== Running Hardware Detection ==="
    source "${LIB_DIR}/hardware-detect.sh"
fi

# Always run base
if [[ "$DRY_RUN" == true ]]; then
    log "[DRY-RUN] Would execute: Base Setup"
    log "[DRY-RUN] Command: source \"${LIB_DIR}/base.sh\""
else
    log "=== Running Base Setup ==="
    source "${LIB_DIR}/base.sh"
fi

# Network manager (essential for wifi connectivity)
if [[ "$DRY_RUN" == true ]]; then
    log "[DRY-RUN] Would execute: Network Manager Setup"
    log "[DRY-RUN] Command: source \"${LIB_DIR}/network.sh\""
else
    log "=== Running Network Manager Setup ==="
    source "${LIB_DIR}/network.sh"
fi

# nvm + Kilo CLI (core requirement)
if [[ "$DRY_RUN" == true ]]; then
    log "[DRY-RUN] Would execute: nvm + Kilo CLI Setup"
    log "[DRY-RUN] Command: source \"${LIB_DIR}/nvm-kilo.sh\""
else
    log "=== Running nvm + Kilo CLI Setup ==="
    source "${LIB_DIR}/nvm-kilo.sh"
fi

# tmux (highly recommended for this workflow)
if [[ "$DRY_RUN" == true ]]; then
    log "[DRY-RUN] Would execute: tmux Setup"
    log "[DRY-RUN] Command: source \"${LIB_DIR}/tmux.sh\""
else
    log "=== Running tmux Setup ==="
    source "${LIB_DIR}/tmux.sh"
fi

# Desktop layers
if [[ "$MODE" == "desktop" || "$MODE" == "full" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        log "[DRY-RUN] Would execute: LXQt Desktop Setup"
        log "[DRY-RUN] Command: source \"${LIB_DIR}/desktop-lxqt.sh\""
    else
        log "=== Running LXQt Desktop Setup ==="
        source "${LIB_DIR}/desktop-lxqt.sh"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "[DRY-RUN] Would execute: Browser Setup"
        log "[DRY-RUN] Command: source \"${LIB_DIR}/browser.sh\""
    else
        log "=== Running Browser Setup ==="
        source "${LIB_DIR}/browser.sh"
    fi
fi

# Future full mode additions can go here
if [[ "$MODE" == "full" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        log "[DRY-RUN] Would execute: Full Mode Additions"
        log "[DRY-RUN] Command: # Add future modules here"
    else
        log "=== Running Full Mode Additions ==="
        # Add future modules here
    fi
fi

#!/usr/bin/env bash
#
# Browser Setup
#
# Goals:
# - Capable GUI browser for the LXQt desktop environment
# - Excellent compatibility with modern web applications and dev tools
# - Idempotent and safe to re-run
# - Uses Debian-packaged Chromium (no third-party repos)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

log "Starting browser setup"

# -----------------------------------------------------------------------------
# 1. Install Chromium
# -----------------------------------------------------------------------------
log "Installing Chromium browser (Debian package)..."
# Chromium is in the non-free repository on Debian
if ! command_exists chromium; then
    # Ensure non-free repos are available for chromium
    if ! grep -q "non-free" /etc/apt/sources.list 2>/dev/null; then
        log "Adding non-free to sources.list for chromium..."
        sudo sed -i 's/main/main non-free/g' /etc/apt/sources.list
        sudo apt update
    fi
    apt_install chromium
fi

# -----------------------------------------------------------------------------
# 2. Optional quality-of-life tweaks (minimal)
# -----------------------------------------------------------------------------
# Create a simple desktop entry hint if needed (Chromium usually provides its own)
if command_exists chromium; then
    log "Chromium installed successfully: $(chromium --version 2>/dev/null | head -1 || echo 'version unknown')"
else
    log "Chromium command not found after installation — may need logout/login"
fi

log "Browser setup complete"
log "Launch with: chromium  (or from the LXQt application menu)"

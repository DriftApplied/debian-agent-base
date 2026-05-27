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
# First ensure package lists are updated
sudo apt update 2>/dev/null || true
# Check if non-free repos are available (needed for chromium on some Debian versions)
if ! apt-cache search chromium 2>/dev/null | grep -q "^chromium "; then
    log "Chromium not found in repos, checking for non-free..."
    if grep -rq "non-free" /etc/apt/sources.list* 2>/dev/null; then
        log "Non-free repos available, updating package lists..."
        sudo apt update
    else
        log "Warning: Non-free repos not configured. Chromium may not be available."
        log "To enable: sudo sed -i 's/ main$/ non-free contrib/' /etc/apt/sources.list && sudo apt update"
    fi
fi
apt_install chromium

# -----------------------------------------------------------------------------
# 2. Optional quality-of-life tweaks (minimal)
# -----------------------------------------------------------------------------
# Create a simple desktop entry hint if needed (Chromium usually provides its own)
if command_exists chromium; then
    log "Chromium installed successfully: $(chromium --version 2>/dev/null | head -1 || echo 'version unknown')"
else
    error "Chromium installation failed. Try manually: sudo apt install chromium"
fi

log "Browser setup complete"
log "Launch with: chromium  (or from the LXQt application menu)"

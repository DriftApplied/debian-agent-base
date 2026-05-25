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
apt_install chromium

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

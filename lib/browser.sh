#!/usr/bin/env bash
#
# Browser Setup
#
# Goals:
# - Provide a functional browser for the desktop experience
# - Use Debian-packaged software only for reliability
# - Keep the script idempotent and simple
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

log "Starting browser setup"

# -----------------------------------------------------------------------------
# 1. Install Firefox as the default browser
# -----------------------------------------------------------------------------
log "Installing Firefox browser (Debian package)..."
apt_install firefox

log "Firefox setup complete"
log "Launch with: firefox (or via the LXQt application menu)"

#!/usr/bin/env bash
#
# nvm + Node + Kilo CLI installation
#
# Goals:
# - Install nvm for the current user
# - Install latest LTS Node via nvm
# - Install Kilo CLI (@kilocode/cli) globally
# - Be idempotent / safe to re-run
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

NVM_VERSION="v0.40.1"                    # Pinned stable version
NVM_DIR="$HOME/.nvm"
NODE_LTS_VERSION="lts/*"                 # Latest LTS

log "Starting nvm + Kilo CLI setup"

# -----------------------------------------------------------------------------
# 1. Install nvm (if not already installed)
# -----------------------------------------------------------------------------
if [[ -d "$NVM_DIR" ]]; then
    log "nvm directory already exists at $NVM_DIR"
else
    log "Installing nvm ($NVM_VERSION)..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

# -----------------------------------------------------------------------------
# 2. Load nvm into current shell
# -----------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command_exists nvm; then
    error "nvm failed to load after installation"
    exit 1
fi

log "nvm loaded successfully"

# -----------------------------------------------------------------------------
# 3. Install latest LTS Node (if not already installed)
# -----------------------------------------------------------------------------
CURRENT_NODE=$(nvm current 2>/dev/null || echo "none")

if nvm ls "$NODE_LTS_VERSION" >/dev/null 2>&1; then
    log "Node LTS already installed"
    nvm use "$NODE_LTS_VERSION" --silent
else
    log "Installing latest Node LTS..."
    nvm install "$NODE_LTS_VERSION"
    nvm alias default "$NODE_LTS_VERSION"
fi

# Make sure we're using the LTS version
nvm use --delete-prefix "$NODE_LTS_VERSION" --silent 2>/dev/null || true

log "Using Node version: $(node -v)"
log "Using npm version:  $(npm -v)"

# -----------------------------------------------------------------------------
# 4. Install Kilo CLI globally (if not already installed)
# -----------------------------------------------------------------------------
if command_exists kilo; then
    log "Kilo CLI is already installed ($(kilo --version 2>/dev/null || echo 'unknown version'))"
else
    log "Installing Kilo CLI..."
    npm install -g @kilocode/cli
fi

# -----------------------------------------------------------------------------
# 5. Ensure nvm is loaded in future shells
# -----------------------------------------------------------------------------
# The official nvm installer already adds the necessary lines to .bashrc,
# but we make sure they exist in case the user has a custom setup.

NVM_LOADER='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

if ! grep -q 'NVM_DIR="$HOME/.nvm"' "$HOME/.bashrc" 2>/dev/null; then
    log "Adding nvm loader to ~/.bashrc"
    echo "" >> "$HOME/.bashrc"
    echo "# nvm" >> "$HOME/.bashrc"
    echo "$NVM_LOADER" >> "$HOME/.bashrc"
fi

log "nvm + Kilo CLI setup complete"
log "You can now run 'kilo' after starting a new shell (or run 'source ~/.bashrc')"

#!/usr/bin/env bash
#
# Base setup - runs on every installation
#
# This script should be idempotent where possible.
#

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

log "Starting base system setup"

# -----------------------------------------------------------------------------
# 1. System Update
# -----------------------------------------------------------------------------
log "Updating package lists and upgrading system"
run sudo apt update
run sudo apt upgrade -y

# -----------------------------------------------------------------------------
# 2. Essential Packages
# -----------------------------------------------------------------------------
log "Installing essential packages"
# Load package list from config file (skip comment lines)
mapfile -t BASE_PACKAGES < <(grep -v '^#' "$SCRIPT_DIR/../config/packages/base.packages" | grep -v '^$')
apt_install "${BASE_PACKAGES[@]}"

# -----------------------------------------------------------------------------
# 3. lm-sensors (auto-configured)
# -----------------------------------------------------------------------------
apt_install lm-sensors

if ! command_exists sensors; then
    log "Configuring lm-sensors (non-interactive)"
    run sudo sensors-detect --auto
else
    log "lm-sensors already appears to be configured"
fi

# -----------------------------------------------------------------------------
# 4. User Environment & Dark Mode
# -----------------------------------------------------------------------------
log "Applying dark console theme and shell improvements"

# Create .bashrc.d directory if it doesn't exist
mkdir -p "$HOME/.bashrc.d"

# Dark mode prompt + basic improvements (can be expanded later)
cat > "$HOME/.bashrc.d/10-dark-theme.sh" << 'EOF'
# Dark theme / improved prompt
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

# Better history
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF

# Source .bashrc.d in .bashrc if not already present
if ! grep -q "# Load custom bash configuration" "$HOME/.bashrc" 2>/dev/null; then
    echo '
# Load custom bash configuration
for file in ~/.bashrc.d/*.sh; do
    [ -r "$file" ] && source "$file"
done
' >> "$HOME/.bashrc"
fi

# -----------------------------------------------------------------------------
# 5. SSH Server
# -----------------------------------------------------------------------------
log "Ensuring SSH server is enabled"
run sudo systemctl enable --now ssh

# -----------------------------------------------------------------------------
# 6. Git Basics (light configuration)
# -----------------------------------------------------------------------------
if ! git config --global user.name >/dev/null 2>&1; then
    log "Git user.name not set. You will need to configure this manually."
fi

log "Base setup complete"

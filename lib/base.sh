#!/usr/bin/env bash
#
# Base setup - runs on every installation
#
# This script should be idempotent where possible.
#

set -euo pipefail

HW_SUMMARY_FILE="/tmp/hardware-info-summary.txt"
# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

enable_nonfree_sources() {
    local release
    release=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    if [[ -z "$release" ]]; then
        warn "Unable to detect Debian release codename; skipping non-free configuration."
        return 0
    fi

    local target_file="/etc/apt/sources.list.d/agent-nonfree.list"
    if [[ -f "$target_file" ]]; then
        if grep -q "contrib non-free" "$target_file" 2>/dev/null; then
            log "Non-free repositories already configured in $target_file"
            return 0
        fi
    fi

    log "Enabling contrib/non-free repositories for ${release}"
    cat <<EOF | sudo tee "$target_file" >/dev/null
deb http://deb.debian.org/debian ${release} main contrib non-free
deb http://deb.debian.org/debian ${release}-updates main contrib non-free
deb http://security.debian.org/debian-security ${release}-security main contrib non-free
EOF
}

log "Starting base system setup"
enable_nonfree_sources

# -----------------------------------------------------------------------------
# 1. System Update
# -----------------------------------------------------------------------------
log "Updating package lists and upgrading system"
retry_run sudo apt update
retry_run sudo apt upgrade -y

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
log "Recording hardware summary for diagnostics"
if [[ -f "/tmp/hardware-info.txt" ]]; then
    cp "/tmp/hardware-info.txt" "/tmp/hardware-info-summary.txt"
    log "Hardware summary saved to /tmp/hardware-info-summary.txt"
else
    log "Hardware summary not found; skipping summary copy"
fi

# -----------------------------------------------------------------------------
# 5. User Environment & Dark Mode
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

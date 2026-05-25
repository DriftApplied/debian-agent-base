#!/usr/bin/env bash
#
# tmux setup
#
# Goals:
# - Good defaults for long-running agent / terminal work
# - Easy to attach to the same session from SSH and local console
# - Increased scrollback history
# - Sensible keybindings and status bar
# - Idempotent
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

TMUX_CONFIG_DIR="$HOME/.config/tmux"
TMUX_CONF="$HOME/.tmux.conf"

log "Starting tmux setup"

# -----------------------------------------------------------------------------
# 1. Ensure tmux is installed
# -----------------------------------------------------------------------------
apt_install tmux

# -----------------------------------------------------------------------------
# 2. Create config directory
# -----------------------------------------------------------------------------
mkdir -p "$TMUX_CONFIG_DIR"

# -----------------------------------------------------------------------------
# 3. Deploy tmux configuration
# -----------------------------------------------------------------------------
log "Installing tmux configuration"

# Copy our config file
cp "${SCRIPT_DIR}/../config/tmux/.tmux.conf" "$TMUX_CONF"

# Also keep a copy in ~/.config/tmux for reference
cp "${SCRIPT_DIR}/../config/tmux/.tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"

# -----------------------------------------------------------------------------
# 4. Ensure tmux is using the config we just installed
# -----------------------------------------------------------------------------
# The config is loaded via ~/.tmux.conf, which we just wrote.

log "tmux configuration installed"

# -----------------------------------------------------------------------------
# 5. Optional: Create a helpful alias for common usage
# -----------------------------------------------------------------------------
if ! grep -q "alias tmux-main" "$HOME/.bashrc" 2>/dev/null; then
    echo '
# Quick tmux session for daily work
alias tmux-main="tmux new-session -A -s main"
' >> "$HOME/.bashrc"
fi

log "tmux setup complete"
log "Recommended: Start new sessions with 'tmux-main' or 'tmux new -s main'"
log "Attach from anywhere with: tmux attach -t main"

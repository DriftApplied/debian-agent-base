#!/usr/bin/env bash
#
# LXQt Desktop Setup (Debloated)
#
# Goals:
# - Minimal, clean LXQt installation
# - No LibreOffice or other heavy bloat
# - Dark theme applied by default
# - Reasonable display manager
# - Idempotent where practical
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

log "Starting debloated LXQt desktop setup"

# -----------------------------------------------------------------------------
# 1. Install minimal LXQt packages (avoiding the full desktop task)
# -----------------------------------------------------------------------------
log "Installing minimal LXQt packages..."

apt_install \
    lxqt-core \
    lxqt-panel \
    lxqt-session \
    lxqt-qtplugin \
    pcmanfm-qt \
    qterminal \
    lxqt-config \
    lxqt-powermanagement \
    lxqt-notificationd \
    lxqt-policykit \
    sddm \
    breeze-icon-theme \
    oxygen-icon-theme

# -----------------------------------------------------------------------------
# 2. Remove common bloat that tends to sneak in
# -----------------------------------------------------------------------------
log "Removing bloat packages (LibreOffice, etc.)..."

BLOAT_PACKAGES=(
    libreoffice*
    mythes-*
    hyphen-*
    hunspell-*
    orage
    mousepad
    ristretto
    vlc
    thunderbird
    evolution
    transmission*
)

for pkg in "${BLOAT_PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg"; then
        log "Purging: $pkg"
        sudo apt purge -y "$pkg" 2>/dev/null || true
    fi
done

sudo apt autoremove --purge -y

# -----------------------------------------------------------------------------
# 3. Set SDDM as default display manager (non-interactive)
# -----------------------------------------------------------------------------
log "Configuring SDDM as display manager..."

sudo debconf-set-selections <<EOF
sddm shared/default-display-manager select /usr/sbin/sddm
EOF

sudo dpkg-reconfigure -f noninteractive sddm

# -----------------------------------------------------------------------------
# 4. Apply dark theme
# -----------------------------------------------------------------------------
log "Applying dark theme to LXQt..."

# Create user config directory
mkdir -p "$HOME/.config/lxqt"

# Set Breeze Dark as the default theme where possible
cat > "$HOME/.config/lxqt/lxqt.conf" << 'EOF'
[General]
__userfile__=true
icon_theme=breeze-dark
theme=Breeze Dark
EOF

# Set Qt style and icon theme for better dark appearance
mkdir -p "$HOME/.config/qt5ct"
cat > "$HOME/.config/qt5ct/qt5ct.conf" << 'EOF'
[Appearance]
color_scheme=Breeze Dark
icon_theme=breeze-dark
style=Breeze
EOF

# Also set for Qt6 if present
mkdir -p "$HOME/.config/qt6ct"
cat > "$HOME/.config/qt6ct/qt6ct.conf" << 'EOF'
[Appearance]
color_scheme=Breeze Dark
icon_theme=breeze-dark
style=Breeze
EOF

# -----------------------------------------------------------------------------
# 5. Set default terminal to qterminal (already installed)
# -----------------------------------------------------------------------------
# This is mostly handled by the minimal package set.

log "LXQt desktop setup complete"
log "A reboot or logout/login is recommended for the desktop to fully appear."

#!/usr/bin/env bash
#
# LXQt Desktop Setup (Debloated)
#
# Goals:
# - Minimal, clean LXQt installation
# - No LibreOffice or other heavy bloat
# - No Plasma / SDDM
# - Uses LightDM (much more appropriate for LXQt)
# - Dark theme applied where possible
# - Idempotent where practical
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

log "Starting debloated LXQt desktop setup"

# -----------------------------------------------------------------------------
# 1. Install minimal LXQt packages
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
    lightdm \
    lightdm-gtk-greeter \
    breeze-icon-theme \
    oxygen-icon-theme

# -----------------------------------------------------------------------------
# 2. Remove common bloat (LibreOffice, etc.)
# -----------------------------------------------------------------------------
log "Removing bloat packages..."

# Use dpkg with grep to find matching packages, then purge them
for pattern in libreoffice mythes hyphen hunspell orage mousepad ristretto vlc thunderbird evolution transmission sddm plasma kde; do
    for pkg in $(dpkg -l | grep "^ii  ${pattern}" | awk '{print $2}'); do
        log "Purging: $pkg"
        sudo apt purge -y "$pkg" 2>/dev/null || true
    done
done

sudo apt autoremove --purge -y

# -----------------------------------------------------------------------------
# 3. Configure LightDM as the default display manager (non-interactive)
# -----------------------------------------------------------------------------
log "Configuring LightDM as display manager..."

sudo debconf-set-selections <<EOF
lightdm shared/default-display-manager select /usr/sbin/lightdm
EOF

sudo dpkg-reconfigure -f noninteractive lightdm

# -----------------------------------------------------------------------------
# 4. Apply dark theme
# -----------------------------------------------------------------------------
log "Applying dark theme to LXQt..."

mkdir -p "$HOME/.config/lxqt"

cat > "$HOME/.config/lxqt/lxqt.conf" << 'EOF'
[General]
__userfile__=true
icon_theme=breeze-dark
theme=Breeze Dark
EOF

# Qt dark theme settings
mkdir -p "$HOME/.config/qt5ct" "$HOME/.config/qt6ct"

cat > "$HOME/.config/qt5ct/qt5ct.conf" << 'EOF'
[Appearance]
color_scheme=Breeze Dark
icon_theme=breeze-dark
style=Breeze
EOF

cat > "$HOME/.config/qt6ct/qt6ct.conf" << 'EOF'
[Appearance]
color_scheme=Breeze Dark
icon_theme=breeze-dark
style=Breeze
EOF

# -----------------------------------------------------------------------------
# 5. Network Manager applet auto-start (for LXQt)
# -----------------------------------------------------------------------------
log "Configuring nm-applet auto-start..."

mkdir -p "$HOME/.config/autostart"

cat > "$HOME/.config/autostart/nm-applet.desktop" << 'EOF'
[Desktop Entry]
Name=Network Manager Applet
Comment=Manage network connections
Exec=nm-applet --indicator
Icon=network-wireless
Terminal=false
Type=Application
NoDisplay=false
Hidden=false
X-GNOME-Autostart-Phase=Initialization
X-GNOME-AutoRestart=true
EOF

log "LXQt desktop setup complete"
log "A reboot is recommended after this run."

#!/usr/bin/env bash
#
# Network Manager Setup (Lightweight)
#
# Goals:
# - Lightweight network management (NetworkManager core only)
# - Automatic detection of USB wifi adapters
# - CLI interface for network selection (nmcli)
# - Desktop integration for LXQt (nm-applet)
# - Idempotent
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

log "Starting network manager setup"

# -----------------------------------------------------------------------------
# 1. Install NetworkManager core components
# -----------------------------------------------------------------------------
# We use NetworkManager (the package) which is the standard lightweight solution
# It doesn't include the full GUI or heavy dependencies by default
log "Installing NetworkManager..."

# Load package list from config file
mapfile -t NETWORK_PACKAGES < "${SCRIPT_DIR}/../config/packages/network.packages"
apt_install "${NETWORK_PACKAGES[@]}"

# -----------------------------------------------------------------------------
# 2. Ensure NetworkManager service is running and enabled
# -----------------------------------------------------------------------------
log "Enabling NetworkManager service..."

# Stop and disable if systemd-networkd is running (common conflict)
if systemctl is-active --quiet systemd-networkd 2>/dev/null; then
    log "Stopping systemd-networkd (conflicts with NetworkManager)"
    run_or_warn sudo systemctl stop systemd-networkd
    run_or_warn sudo systemctl disable systemd-networkd
fi

# Enable and start NetworkManager
run_or_warn sudo systemctl enable --now NetworkManager

# -----------------------------------------------------------------------------
# 3. Create CLI helper script for network selection
# -----------------------------------------------------------------------------
log "Creating network selection helper..."

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/nm-select" << 'EOF'
#!/usr/bin/env bash
# Quick wifi network selector using nmcli

echo "Scanning for networks..."
nmcli -t -f ssid,signal,security device wifi list 2>/dev/null | sort -t $'\t' -k2 -nr | head -20 > /tmp/nm-scan.txt

if [[ ! -s /tmp/nm-scan.txt ]]; then
    echo "No networks found or no wifi device available"
    echo "Make sure your USB wifi adapter is plugged in."
    exit 1
fi

echo ""
echo "Available networks:"
echo "=================="
i=1
while IFS=$'\t' read -r ssid signal security; do
    [[ -z "$ssid" ]] && ssid="(hidden network)"
    printf "%2d) %-30s %s\n" "$i" "$ssid" "$([[ -n "$security" ]] && echo "[$security]")"
    i=$((i + 1))
done < /tmp/nm-scan.txt

echo ""
read -p "Enter network number (or press Enter to cancel): " choice

if [[ -z "$choice" ]]; then
    echo "Cancelled."
    exit 0
fi

# Get the SSID for the chosen number
selected_ssid=$(sed -n "${choice}p" /tmp/nm-scan.txt | cut -f1)

if [[ -z "$selected_ssid" ]]; then
    echo "Invalid selection."
    exit 1
fi

echo "Connecting to '$selected_ssid'..."

# Check if network is open or secured, and connect accordingly
line=$(sed -n "${choice}p" /tmp/nm-scan.txt)
security=$(echo "$line" | cut -f3)

if [[ -z "$security" || "$security" == "--" ]]; then
    # Open network - connect directly
    nmcli device wifi connect "$selected_ssid" 2>&1 || {
        echo "Connection failed."
        exit 1
    }
else
    # Secured network - nmcli will prompt for password
    nmcli device wifi connect "$selected_ssid" 2>&1 || {
        echo ""
        echo "Connection failed. You may need to connect manually:"
        echo "  nmcli device wifi connect \"$selected_ssid\" password <your_password>"
        exit 1
    }
fi

echo "Connected. Check status with: nma"
EOF

chmod +x "$HOME/.local/bin/nm-select"

# Ensure ~/.local/bin exists in PATH
if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo '' >> "$HOME/.bashrc"
    echo '# User local bin' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# -----------------------------------------------------------------------------
# 4. Create quick aliases for common network tasks
# -----------------------------------------------------------------------------
if ! grep -q "alias nml" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" << 'EOF'

# Network shortcuts
alias nml='nmcli device wifi list'        # List networks
alias nmc='nmcli connection show'         # Show connections
alias nma='nmcli connection show --active' # Active connections
EOF
fi

log "Network manager setup complete"
log "CLI: Run 'nm-select' to connect to wifi networks"
log "CLI: Use 'nml' to list available networks, 'nma' for active connections"
log "Desktop: nm-applet will appear in system tray after login"
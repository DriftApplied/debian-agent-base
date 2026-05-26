#!/usr/bin/env bash
#
# Hardware detection and validation
#
# Goals:
# - Detect system hardware characteristics
# - Validate that essential hardware is present and functioning
# - Log information for debugging and optimization
# - Optionally apply hardware-based optimizations
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

log "Starting hardware detection"

# Create a temporary file to store hardware info for summary
HW_INFO_FILE="/tmp/hardware-info.txt"
: > "$HW_INFO_FILE"

# Function to append to hardware info file and also log
hw_log() {
    echo "$*" | tee -a "$HW_INFO_FILE"
}

hw_log "=== Hardware Detection Summary ==="
hw_log "Timestamp: $(date)"
hw_log "Hostname: $(hostname)"
hw_log ""

# -----------------------------------------------------------------------------
# 1. CPU Information
# -----------------------------------------------------------------------------
hw_log "CPU Information:"
if command_exists lscpu; then
    lscpu | tee -a "$HW_INFO_FILE"
else
    # Fallback to /proc/cpuinfo
    hw_log "Model: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ //')"
    hw_log "Architecture: $(grep 'architecture' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ //')"
    hw_log "CPU(s): $(grep '^processor' /proc/cpuinfo | wc -l)"
    hw_log "Core(s) per socket: $(grep 'core id' /proc/cpuinfo | sort -u | wc -l)"
    hw_log "Socket(s): $(grep 'physical id' /proc/cpuinfo | sort -u | wc -l)"
fi
hw_log ""

# -----------------------------------------------------------------------------
# 2. Memory Information
# -----------------------------------------------------------------------------
hw_log "Memory Information:"
if command_exists free; then
    free -h | tee -a "$HW_INFO_FILE"
else
    hw_log "MemTotal: $(grep 'MemTotal' /proc/meminfo | awk '{print $2}') kB"
    hw_log "MemAvailable: $(grep 'MemAvailable' /proc/meminfo | awk '{print $2}') kB"
fi
hw_log ""

# -----------------------------------------------------------------------------
# 3. Storage Information
# -----------------------------------------------------------------------------
hw_log "Storage Information:"
if command_exists lsblk; then
    hw_log "Disk layout:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | tee -a "$HW_INFO_FILE"
else
    hw_log "Mount points:"
    mount | grep '^/dev' | tee -a "$HW_INFO_FILE"
fi

# Check for rotational vs SSD
if [ -d /sys/block ]; then
    hw_log ""
    hw_log "Disk rotation type (1=HDD, 0=SSD):"
    for disk in /sys/block/*; do
        diskname=$(basename "$disk")
        if [ -f "$disk/queue/rotational" ]; then
            rotational=$(cat "$disk/queue/rotational")
            hw_log "  $diskname: $rotational"
        fi
    done
fi
hw_log ""

# -----------------------------------------------------------------------------
# 4. PCI Devices (Graphics, Network, etc.)
# -----------------------------------------------------------------------------
hw_log "PCI Devices:"
if command_exists lspci; then
    lspci | tee -a "$HW_INFO_FILE"
else
    hw_log "lspci not available; skipping detailed PCI list"
fi
hw_log ""

# -----------------------------------------------------------------------------
# 5. USB Devices
# -----------------------------------------------------------------------------
hw_log "USB Devices:"
if command_exists lsusb; then
    lsusb | tee -a "$HW_INFO_FILE"
else
    hw_log "lsusb not available; skipping USB list"
fi
hw_log ""

# -----------------------------------------------------------------------------
# 6. Network Interfaces
# -----------------------------------------------------------------------------
hw_log "Network Interfaces:"
hw_log "Wired interfaces:"
# Common wired interface prefixes: eno, ens, enp, enx, eth, em
ip -o link show | grep -E '^[0-9]+: (eno|ens|enp|enx|eth|em)' | tee -a "$HW_INFO_FILE"
hw_log "Wireless interfaces:"
# Common wireless interface prefixes: wlan, wifi, wlx, ath, ww
ip -o link show | grep -E '^[0-9]+: (wlan|wifi|wlx|ath|ww)' | tee -a "$HW_INFO_FILE"
hw_log ""

# -----------------------------------------------------------------------------
# 7. Audio
# -----------------------------------------------------------------------------
hw_log "Audio Devices:"
if command_exists lspci; then
    lspci | grep -i audio | tee -a "$HW_INFO_FILE"
else
    hw_log "Checking via /proc/asound/cards:"
    if [ -f /proc/asound/cards ]; then
        cat /proc/asound/cards | tee -a "$HW_INFO_FILE"
    else
        hw_log "No audio devices found"
    fi
fi
hw_log ""

# -----------------------------------------------------------------------------
# 8. Graphics and Display
# -----------------------------------------------------------------------------
hw_log "Graphics Information:"
if command_exists lspci; then
    lspci | grep -i -E 'vga|3d|display' | tee -a "$HW_INFO_FILE"
else
    hw_log "Checking /proc/fb:"
    if [ -f /proc/fb ]; then
        cat /proc/fb | tee -a "$HW_INFO_FILE"
    else
        hw_log "No framebuffer devices"
    fi
fi
hw_log ""

# -----------------------------------------------------------------------------
# 9. System Information
# -----------------------------------------------------------------------------
hw_log "System Information:"
hw_log "Kernel: $(uname -r)"
hw_log "Architecture: $(uname -m)"
hw_log "Virtualization: $(systemd-detect-virt 2>/dev/null || echo "unknown")"
hw_log ""

# -----------------------------------------------------------------------------
# 10. Sensors and Power
# -----------------------------------------------------------------------------
hw_log "Sensors (if available):"
if command_exists sensors; then
    sensors | tee -a "$HW_INFO_FILE"
else
    hw_log "lm-sensors not installed or no sensors detected"
fi
hw_log ""

# -----------------------------------------------------------------------------
# 11. Boot and Systemd
# -----------------------------------------------------------------------------
hw_log "Systemd Information:"
hw_log "Default target: $(systemctl get-default 2>/dev/null || echo "unknown")"
hw_log "Failed units: $(systemctl --failed --no-legend | wc -l)"
hw_log ""

hw_log "=== End of Hardware Detection ==="

# Log a summary to the main log as well
log "Hardware detection complete. Details written to $HW_INFO_FILE"
log "Key findings:"
# Extract some key points for the main log
if grep -q "Model:" "$HW_INFO_FILE"; then
    grep "Model:" "$HW_INFO_FILE" | head -1 | while read line; do
        log "  CPU: $line"
    done
fi
if grep -q "MemTotal:" "$HW_INFO_FILE"; then
    grep "MemTotal:" "$HW_INFO_FILE" | head -1 | while read line; do
        log "  Memory: $line"
    done
fi
if grep -q "Disk rotation type" "$HW_INFO_FILE"; then
    grep -A5 "Disk rotation type" "$HW_INFO_FILE" | grep -v "Disk rotation type" | head -3 | while read line; do
        log "  Disk: $line"
    done
fi

# Check for any critical issues
# For example, if no network interfaces detected, warn
if ! ip -o link show | grep -q -E '^[0-9]+: (eno|ens|enp|enx|eth|em|wlan|wifi|wlx|ath|ww)'; then
    warn "No network interfaces detected!"
fi

# Clean up temp file? We'll leave it for debugging; maybe remove later.
# rm -f "$HW_INFO_FILE"
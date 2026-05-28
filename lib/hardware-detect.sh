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

hw_log() {
    log "$*"
}

hw_summary_line() {
    echo "$*" >> "$HW_INFO_FILE"
}

hw_log_summary() {
    hw_log "$*"
    hw_summary_line "$*"
}

hw_log_summary "=== Hardware Detection Summary ==="
hw_log_summary "Timestamp: $(date)"
hw_log_summary "Hostname: $(hostname)"
hw_log ""

# -----------------------------------------------------------------------------
# 1. CPU Information
# -----------------------------------------------------------------------------
hw_log "CPU Information:"
if command_exists lscpu; then
    run lscpu
else
    hw_log "lscpu not available; falling back to /proc/cpuinfo"
fi
hw_log ""

cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')
cpu_architecture=$(grep -m1 'architecture' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')
cpu_count=$(grep -c '^processor' /proc/cpuinfo)
cpu_cores=$(grep -m1 'core id' /proc/cpuinfo | sort -u | wc -l)
cpu_sockets=$(grep -m1 'physical id' /proc/cpuinfo | sort -u | wc -l)

[[ -n "$cpu_model" ]] && hw_log_summary "Model: $cpu_model"
[[ -n "$cpu_architecture" ]] && hw_log_summary "Architecture: $cpu_architecture"
[[ -n "$cpu_count" ]] && hw_log_summary "CPU(s): $cpu_count"
[[ -n "$cpu_cores" ]] && hw_log_summary "Core(s) per socket: $cpu_cores"
[[ -n "$cpu_sockets" ]] && hw_log_summary "Socket(s): $cpu_sockets"
hw_log ""

# -----------------------------------------------------------------------------
# 2. Memory Information
# -----------------------------------------------------------------------------
hw_log "Memory Information:"
if command_exists free; then
    run free -h
else
    hw_log "free command not available; reading /proc/meminfo"
fi
hw_log ""

mem_total=$(grep 'MemTotal' /proc/meminfo | awk '{print $2}')
mem_available=$(grep 'MemAvailable' /proc/meminfo | awk '{print $2}')
[[ -n "$mem_total" ]] && hw_log_summary "MemTotal: ${mem_total} kB"
[[ -n "$mem_available" ]] && hw_log_summary "MemAvailable: ${mem_available} kB"
hw_log ""

# -----------------------------------------------------------------------------
# 3. Storage Information
# -----------------------------------------------------------------------------
hw_log "Storage Information:"
if command_exists lsblk; then
    hw_log "Disk layout:"
    run lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
else
    hw_log "Mount points:"
    mount | grep '^/dev' || true
fi
hw_log ""

# Check for rotational vs SSD
if [ -d /sys/block ]; then
    hw_log ""
    hw_log_summary "Disk rotation type (1=HDD, 0=SSD):"
    for disk in /sys/block/*; do
        diskname=$(basename "$disk")
        if [ -f "$disk/queue/rotational" ]; then
            rotational=$(cat "$disk/queue/rotational")
            hw_log "  $diskname: $rotational"
            hw_summary_line "  $diskname: $rotational"
        fi
    done
fi
hw_log ""

# -----------------------------------------------------------------------------
# 4. PCI Devices (Graphics, Network, etc.)
# -----------------------------------------------------------------------------
hw_log "PCI Devices:"
if command_exists lspci; then
    run lspci
else
    hw_log "lspci not available; skipping detailed PCI list"
fi
hw_log ""

# -----------------------------------------------------------------------------
# 5. USB Devices
# -----------------------------------------------------------------------------
hw_log "USB Devices:"
if command_exists lsusb; then
    run lsusb
else
    hw_log "lsusb not available; skipping USB list"
fi
hw_log ""

# -----------------------------------------------------------------------------
# 6. Network Interfaces
# -----------------------------------------------------------------------------
hw_log "Network Interfaces:"
hw_log "Wired interfaces:"
wired_matches=$(ip -o link show | grep -E '^[0-9]+: (eno|ens|enp|enx|eth|em)' || true)
if [[ -n "$wired_matches" ]]; then
    log "$wired_matches"
    hw_log_summary "Wired interfaces: $(echo "$wired_matches" | wc -l)"
else
    hw_log "  None detected"
    hw_log_summary "Wired interfaces: 0"
fi
hw_log "Wireless interfaces:"
wireless_matches=$(ip -o link show | grep -E '^[0-9]+: (wlan|wifi|wlx|ath|ww)' || true)
if [[ -n "$wireless_matches" ]]; then
    log "$wireless_matches"
    hw_log_summary "Wireless interfaces: $(echo "$wireless_matches" | wc -l)"
else
    hw_log "  None detected"
    hw_log_summary "Wireless interfaces: 0"
fi
hw_log ""

# -----------------------------------------------------------------------------
# 7. Audio
# -----------------------------------------------------------------------------
hw_log "Audio Devices:"
if command_exists lspci; then
    lspci | grep -i audio || true
else
    hw_log "Checking via /proc/asound/cards:"
    if [ -f /proc/asound/cards ]; then
        cat /proc/asound/cards
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
    lspci | grep -i -E 'vga|3d|display' || true
else
    hw_log "Checking /proc/fb:"
    if [ -f /proc/fb ]; then
        cat /proc/fb
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
    run sensors
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

#!/usr/bin/env bash
#
# Shared utility functions
#

# Run a command and log it
run() {
    log "Running: $*"
    "$@"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a package is installed (Debian/Ubuntu)
package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

# Safe apt install (only if not already installed)
apt_install() {
    local pkgs=("$@")
    local to_install=()

    for pkg in "${pkgs[@]}"; do
        if ! package_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log "Installing packages: ${to_install[*]}"
        sudo apt install -y "${to_install[@]}"
    else
        log "All requested packages already installed: ${pkgs[*]}"
    fi
}

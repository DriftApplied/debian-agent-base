#!/usr/bin/env bash
#
# Shared utility functions
#

# Log function with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Error log function
error() {
    echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

# Warning log function
warn() {
    echo "[WARN] $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

# Run a command and log it with error handling
run() {
    log "Running: $*"
    if "$@"; then
        return 0
    else
        error "Command failed: $*"
        return 1
    fi
}

# Run a command and log it, but don't fail on error
run_or_warn() {
    log "Running: $*"
    if ! "$@"; then
        warn "Command failed (continuing): $*"
        return 1
    fi
    return 0
}

# Retry-aware runner for flaky network commands
retry_run() {
    local attempts=3
    local delay=5
    local attempt=1

    while true; do
        if run "$@"; then
            return 0
        fi

        if (( attempt >= attempts )); then
            error "Command failed after ${attempts} attempts: $*"
            return 1
        fi

        log "Retrying in ${delay}s (attempt $((attempt + 1))/${attempts})..."
        sleep "$delay"
        ((attempt++))
    done
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
        if retry_run sudo apt install -y "${to_install[@]}"; then
            log "Successfully installed: ${to_install[*]}"
        else
            error "Failed to install packages: ${to_install[*]}"
            return 1
        fi
    else
        log "All requested packages already installed: ${pkgs[*]}"
    fi
}

#!/usr/bin/env bash
# lib/packages.sh — Package management via dnf (Fedora only).
# Sourced by install.sh; not executed directly.

# ── Install packages ──────────────────────────────────────────────────────────
# Usage: packages_install pkg1 pkg2 …
# Retries up to 3 times on transient errors.
packages_install() {
    local -r max_retries=3
    local attempt

    for attempt in $(seq 1 "${max_retries}"); do
        core_log_info "Installing packages (attempt ${attempt}/${max_retries}): $*"

        if sudo dnf install -y "$@"; then
            return 0
        fi

        core_log_warn "Install attempt ${attempt} failed; retrying…"
        sleep 2
    done

    core_log_error "Failed to install packages after ${max_retries} attempts: $*"
    return 1
}

# ── Check if a package is installed ──────────────────────────────────────────
# Usage: if packages_is_installed <pkg>; then …; fi
packages_is_installed() {
    local pkg="${1:?packages_is_installed: package name required}"
    rpm -q "${pkg}" &>/dev/null
}

# ── Verify rofi-wayland is installed (not X11 rofi) ──────────────────────────
# Usage: packages_verify_rofi_wayland
# Returns 0 if rofi-wayland is installed, 1 otherwise.
packages_verify_rofi_wayland() {
    if rpm -q rofi-wayland &>/dev/null; then
        core_log_info "rofi-wayland is installed (Wayland-native)."
        return 0
    fi

    core_log_error "rofi-wayland is NOT installed."

    if rpm -q rofi &>/dev/null; then
        core_log_warn "Standard X11 'rofi' is installed; replace it with 'rofi-wayland' for Wayland support."
        core_log_warn "  sudo dnf swap rofi rofi-wayland"
    else
        core_log_warn "Install rofi-wayland via: sudo dnf install -y rofi-wayland"
    fi

    return 1
}


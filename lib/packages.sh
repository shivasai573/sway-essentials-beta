#!/usr/bin/env bash
# lib/packages.sh — Package manager abstraction with retries.
# Sourced by install.sh; not executed directly.

# ── Package manager detection ─────────────────────────────────────────────────
# Sets PKG_MANAGER to one of: apt, dnf, pacman, zypper
# Delegates to scripts/detect-pkg-manager.sh.
PKG_MANAGER=""

packages_detect() {
    local detect_script
    detect_script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/detect-pkg-manager.sh"

    if [[ ! -x "${detect_script}" ]]; then
        core_log_error "detect-pkg-manager.sh not found or not executable: ${detect_script}"
        return 1
    fi

    PKG_MANAGER="$("${detect_script}")"

    if [[ -z "${PKG_MANAGER}" ]]; then
        core_log_error "Could not detect a supported package manager."
        core_log_error "Supported: apt, dnf, pacman, zypper"
        return 1
    fi

    core_log_info "Detected package manager: ${PKG_MANAGER}"
}

# ── Install packages ──────────────────────────────────────────────────────────
# Usage: packages_install pkg1 pkg2 …
# Retries up to 3 times on transient errors.
packages_install() {
    if [[ -z "${PKG_MANAGER}" ]]; then
        packages_detect
    fi

    local -r max_retries=3
    local attempt

    for attempt in $(seq 1 "${max_retries}"); do
        core_log_info "Installing packages (attempt ${attempt}/${max_retries}): $*"

        case "${PKG_MANAGER}" in
            apt)     sudo apt-get install -y "$@" && return 0 ;;
            dnf)     sudo dnf install -y "$@"     && return 0 ;;
            pacman)  sudo pacman -S --noconfirm "$@" && return 0 ;;
            zypper)  sudo zypper install -y "$@"  && return 0 ;;
            *)
                core_log_error "Unsupported package manager: ${PKG_MANAGER}"
                return 1
                ;;
        esac

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

    case "${PKG_MANAGER}" in
        apt)    dpkg -s "${pkg}" &>/dev/null ;;
        dnf)    rpm -q "${pkg}" &>/dev/null ;;
        pacman) pacman -Q "${pkg}" &>/dev/null ;;
        zypper) rpm -q "${pkg}" &>/dev/null ;;
        *)      command -v "${pkg}" &>/dev/null ;;
    esac
}

#!/usr/bin/env bash
# lib/core.sh — Core utilities: logging, dependency checks, helpers.
# Sourced by install.sh; not executed directly.

# ── Colours ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    _CLR_RESET='\033[0m'
    _CLR_INFO='\033[0;32m'   # green
    _CLR_WARN='\033[0;33m'   # yellow
    _CLR_ERROR='\033[0;31m'  # red
    _CLR_BOLD='\033[1m'
else
    _CLR_RESET=''
    _CLR_INFO=''
    _CLR_WARN=''
    _CLR_ERROR=''
    _CLR_BOLD=''
fi

# ── Logging ───────────────────────────────────────────────────────────────────
core_log_info() {
    echo -e "${_CLR_INFO}[INFO]${_CLR_RESET}  $*" >&2
}

core_log_warn() {
    echo -e "${_CLR_WARN}[WARN]${_CLR_RESET}  $*" >&2
}

core_log_error() {
    echo -e "${_CLR_ERROR}[ERROR]${_CLR_RESET} $*" >&2
}

core_log_bold() {
    echo -e "${_CLR_BOLD}$*${_CLR_RESET}" >&2
}

# ── Dependency check ──────────────────────────────────────────────────────────
core_check_dependencies() {
    local missing=()

    for cmd in gum git; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        core_log_error "Missing required tools: ${missing[*]}"
        core_log_error "Install them and re-run this script."
        core_log_error "  gum:  https://github.com/charmbracelet/gum#installation"
        core_log_error "  git:  https://git-scm.com/"
        exit 1
    fi
}

# ── Safe copy helper ──────────────────────────────────────────────────────────
# Usage: core_safe_copy <src> <dest>
# Creates parent dirs, backs up existing dest via backup module if available.
core_safe_copy() {
    local src="${1:?core_safe_copy: source required}"
    local dest="${2:?core_safe_copy: destination required}"

    if [[ ! -f "${src}" ]]; then
        core_log_error "Source file not found: ${src}"
        return 1
    fi

    mkdir -p "$(dirname "${dest}")"

    if [[ -e "${dest}" ]]; then
        # Delegate backup to backup module if loaded
        if declare -f backup_file &>/dev/null; then
            backup_file "${dest}"
        fi
    fi

    cp -f "${src}" "${dest}"
    core_log_info "Copied: ${src} → ${dest}"
}

# ── Safe symlink helper ───────────────────────────────────────────────────────
# Usage: core_safe_symlink <target> <link_path>
core_safe_symlink() {
    local target="${1:?core_safe_symlink: target required}"
    local link="${2:?core_safe_symlink: link path required}"

    mkdir -p "$(dirname "${link}")"

    if [[ -e "${link}" || -L "${link}" ]]; then
        if declare -f backup_file &>/dev/null; then
            backup_file "${link}"
        fi
        rm -f "${link}"
    fi

    ln -s "${target}" "${link}"
    core_log_info "Symlinked: ${link} → ${target}"
}

# ── Config directory ─────────────────────────────────────────────────────────
# Absolute path to the configs/ directory shipped with this project.
# Used by sourced modules (aesthetics.sh, etc.) — not directly in this file.
# shellcheck disable=SC2034
CONFIGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../configs" && pwd)"
# shellcheck disable=SC2034
readonly CONFIGS_DIR

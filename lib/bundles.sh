#!/usr/bin/env bash
# lib/bundles.sh — Workflow App Bundles module.
# Multi-select bundles and install corresponding package lists.
# Sourced by install.sh; not executed directly.

# ── Bundle definitions ────────────────────────────────────────────────────────
# Each bundle maps to a list of packages.
declare -A _BUNDLE_PKGS
_BUNDLE_PKGS["Terminal Setup"]="foot tmux zsh"
_BUNDLE_PKGS["Developer Core"]="git curl wget jq fzf ripgrep neovim"
_BUNDLE_PKGS["Multimedia"]="mpv imv pavucontrol pipewire wireplumber"

module_app_bundles() {
    core_log_bold "── Workflow App Bundles ──────────────────────────────────"

    local selected
    selected="$(ui_multiselect "Select bundles to install (SPACE to toggle, ENTER to confirm):" \
        "Terminal Setup" \
        "Developer Core" \
        "Multimedia")" || true

    if [[ -z "${selected}" ]]; then
        core_log_info "App bundles: nothing selected or cancelled."
        return 0
    fi


    local bundle
    while IFS= read -r bundle; do
        [[ -z "${bundle}" ]] && continue
        _bundles_install_bundle "${bundle}"
    done <<< "${selected}"

    core_log_info "App bundles installation complete."
}

# ── Install starship via the official curl script ─────────────────────────────
_bundles_install_starship() {
    core_log_info "Installing starship via official curl script…"
    if curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        core_log_info "starship installed successfully."
    else
        core_log_error "Failed to install starship via curl script."
        return 1
    fi
}

# ── Install a single bundle ───────────────────────────────────────────────────
_bundles_install_bundle() {
    local name="${1:?_bundles_install_bundle: bundle name required}"
    local pkgs="${_BUNDLE_PKGS[${name}]:-}"

    if [[ -z "${pkgs}" ]]; then
        core_log_warn "Unknown bundle: '${name}'; skipping."
        return 0
    fi

    core_log_info "Installing bundle '${name}': ${pkgs}"
    # shellcheck disable=SC2086
    packages_install ${pkgs}

    if [[ "${name}" == "Terminal Setup" ]]; then
        _bundles_install_starship
    fi
}

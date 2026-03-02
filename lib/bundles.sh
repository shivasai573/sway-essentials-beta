#!/usr/bin/env bash
# lib/bundles.sh — Workflow App Bundles module.
# Multi-select bundles and install corresponding package lists.
# Sourced by install.sh; not executed directly.

# ── Bundle definitions ────────────────────────────────────────────────────────
# Each bundle maps to a list of packages.
declare -A _BUNDLE_PKGS
_BUNDLE_PKGS["Terminal Setup"]="foot tmux zsh starship"
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
}

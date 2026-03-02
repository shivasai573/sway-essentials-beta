#!/usr/bin/env bash
# lib/aesthetics.sh — Aesthetic Engine module.
# Handles theme selection, Waybar layout, and Rofi style.
# Sourced by install.sh; not executed directly.

module_aesthetics() {
    core_log_bold "── Aesthetic Engine ──────────────────────────────────────"

    # 1) Theme selection
    local theme
    theme="$(ui_choose "Select colour theme:" "Catppuccin" "Nord")" || true
    if [[ -z "${theme}" ]]; then
        core_log_info "Aesthetics: cancelled."
        return 0
    fi

    # 2) Waybar layout
    local waybar_layout
    waybar_layout="$(ui_choose "Select Waybar layout:" "minimal-top" "floating-bottom")" || true
    if [[ -z "${waybar_layout}" ]]; then
        core_log_info "Aesthetics: cancelled."
        return 0
    fi

    # 3) Rofi style (derived from theme)
    local rofi_style
    rofi_style="$(echo "${theme}" | tr '[:upper:]' '[:lower:]')"  # catppuccin or nord

    core_log_info "Applying theme=${theme}, waybar=${waybar_layout}, rofi=${rofi_style}"

    _aesthetics_apply_waybar "${waybar_layout}"
    _aesthetics_apply_rofi   "${rofi_style}"

    core_log_info "Aesthetic Engine complete."
}

# ── Apply Waybar config ───────────────────────────────────────────────────────
_aesthetics_apply_waybar() {
    local layout="${1:?_aesthetics_apply_waybar: layout required}"
    local src_dir="${CONFIGS_DIR}/waybar/${layout}"
    local dest_dir="${HOME}/.config/waybar"

    if [[ ! -d "${src_dir}" ]]; then
        core_log_warn "Waybar config directory not found: ${src_dir}"
        return 0
    fi

    core_safe_copy "${src_dir}/config.jsonc" "${dest_dir}/config.jsonc"
    core_safe_copy "${src_dir}/style.css"    "${dest_dir}/style.css"
}

# ── Apply Rofi theme ──────────────────────────────────────────────────────────
_aesthetics_apply_rofi() {
    local style="${1:?_aesthetics_apply_rofi: style required}"
    local src="${CONFIGS_DIR}/rofi/${style}.rasi"
    local dest="${HOME}/.config/rofi/${style}.rasi"

    if [[ ! -f "${src}" ]]; then
        core_log_warn "Rofi theme not found: ${src}"
        return 0
    fi

    core_safe_copy "${src}" "${dest}"
}

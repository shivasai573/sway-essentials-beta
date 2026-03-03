#!/usr/bin/env bash
# lib/aesthetics.sh — Aesthetic Engine module.
# Handles theme selection, Waybar layout, Rofi style, and font installation.
# Sourced by install.sh; not executed directly.

module_aesthetics() {
    core_log_bold "── Aesthetic Engine ──────────────────────────────────────"

    core_log_info "Installing core UI packages..."
    packages_install waybar rofi-wayland swaybg fontawesome-fonts curl unzip grim slurp wl-clipboard brightnessctl

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

    _aesthetics_apply_sway
    _aesthetics_select_wallpaper
    _aesthetics_install_fonts
    _aesthetics_apply_waybar "${waybar_layout}"
    _aesthetics_apply_rofi   "${rofi_style}"
    _aesthetics_apply_wayland_env

    # Live reload — restart Waybar to pick up new fonts, then reload Sway
    pkill waybar 2>/dev/null || true
    swaymsg reload >/dev/null 2>&1 || true

    core_log_info "Aesthetic Engine complete."
}

# ── Select and deploy wallpaper ───────────────────────────────────────────────
_aesthetics_select_wallpaper() {
    local wallpaper_dir="${CONFIGS_DIR}/wallpapers"
    local dest_dir="${HOME}/.config/sway"
    local dest_wallpaper="${dest_dir}/wallpaper"

    mkdir -p "${dest_dir}"

    # Collect non-hidden wallpaper files from the wallpapers directory
    local -a wallpapers=()
    while IFS= read -r -d '' f; do
        wallpapers+=("$(basename "${f}")")
    done < <(find "${wallpaper_dir}" -maxdepth 1 -type f -not -name '.*' -print0 2>/dev/null)

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        core_log_warn "No wallpapers found in ${wallpaper_dir}; using solid colour fallback."
        _aesthetics_set_wallpaper_fallback "${dest_dir}"
        return 0
    fi

    local selected
    selected="$(ui_choose "Select a wallpaper:" "${wallpapers[@]}")" || true

    if [[ -z "${selected}" ]]; then
        core_log_info "Wallpaper: no selection; using solid colour fallback."
        _aesthetics_set_wallpaper_fallback "${dest_dir}"
        return 0
    fi

    # Strip any path components — ui_choose only returns basenames, but guard
    # against unexpected values that could traverse outside wallpaper_dir.
    selected="$(basename "${selected}")"

    cp -f "${wallpaper_dir}/${selected}" "${dest_wallpaper}"
    # Write the override so wallpaper.conf always wins over the template default.
    # Quote the path to handle filenames with spaces or special characters.
    printf 'output * bg "%s" fill\n' "${dest_wallpaper}" > "${dest_dir}/wallpaper.conf"
    core_log_info "Wallpaper set: ${dest_wallpaper} (${selected})"
}

# ── Write solid-colour wallpaper fallback ─────────────────────────────────────
_aesthetics_set_wallpaper_fallback() {
    local dest_dir="${1:?_aesthetics_set_wallpaper_fallback: dest dir required}"
    printf 'output * bg #1e1e2e solid_color\n' > "${dest_dir}/wallpaper.conf"
    core_log_info "Solid colour fallback written to ${dest_dir}/wallpaper.conf"
}

# ── Install Nerd Fonts (JetBrainsMono) ───────────────────────────────────────
_aesthetics_install_fonts() {
    local font_dir="${HOME}/.local/share/fonts/JetBrainsMono"
    local zip_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    local tmp_zip

    # Idempotency: skip download if font files are already present
    if ls "${font_dir}"/*.ttf >/dev/null 2>&1; then
        core_log_info "JetBrainsMono Nerd Font already installed; skipping download."
        return 0
    fi

    tmp_zip="$(mktemp /tmp/JetBrainsMono-XXXXXX.zip)"

    core_log_info "Downloading JetBrainsMono Nerd Font…"
    if ! curl -fsSL "${zip_url}" -o "${tmp_zip}"; then
        core_log_warn "Failed to download JetBrainsMono font; skipping."
        rm -f "${tmp_zip}"
        return 0
    fi

    mkdir -p "${font_dir}"
    if ! unzip -o "${tmp_zip}" -d "${font_dir}" >/dev/null; then
        core_log_warn "Failed to unzip JetBrainsMono font; skipping."
        rm -f "${tmp_zip}"
        return 0
    fi

    rm -f "${tmp_zip}"
    core_log_info "Rebuilding font cache…"
    fc-cache -f -v
    core_log_info "JetBrainsMono Nerd Font installed to ${font_dir}"
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

    core_safe_symlink "${src_dir}/config.jsonc" "${dest_dir}/config.jsonc"
    core_safe_symlink "${src_dir}/style.css"    "${dest_dir}/style.css"
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

    core_safe_symlink "${src}" "${dest}"
}

# ── Deploy Sway master config ─────────────────────────────────────────────────
_aesthetics_apply_sway() {
    local src="${CONFIGS_DIR}/sway/config"
    local dest="${HOME}/.config/sway/config"

    if [[ ! -f "${src}" ]]; then
        core_log_warn "Sway config not found: ${src}"
        return 0
    fi

    core_safe_symlink "${src}" "${dest}"
}

# ── Deploy Wayland environment.d config ──────────────────────────────────────
_aesthetics_apply_wayland_env() {
    local src="${CONFIGS_DIR}/environment.d/wayland.conf"
    local dest="${HOME}/.config/environment.d/wayland.conf"

    if [[ ! -f "${src}" ]]; then
        core_log_warn "Wayland environment config not found: ${src}"
        return 0
    fi

    core_safe_symlink "${src}" "${dest}"
    core_log_info "Wayland environment variables will be active on next login."
}

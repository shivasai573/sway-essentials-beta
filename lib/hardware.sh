#!/usr/bin/env bash
# lib/hardware.sh — Hardware & Input Auto-Tuning module.
# Detects laptops heuristically and injects input config idempotently.
# Sourced by install.sh; not executed directly.

# Sway config path (respects XDG)
_SWAY_CONFIG="${HOME}/.config/sway/config"

module_hardware_tuning() {
    core_log_bold "── Hardware & Input Auto-Tuning ──────────────────────────"

    if _hardware_is_laptop; then
        core_log_info "Laptop hardware detected."
        _hardware_inject_laptop_input
    else
        core_log_info "Non-laptop hardware detected; skipping laptop input config."
    fi

    core_log_info "Hardware tuning complete."
}

# ── Laptop detection ──────────────────────────────────────────────────────────
# Heuristic: presence of a battery device under /sys implies a laptop.
_hardware_is_laptop() {
    local battery_path="/sys/class/power_supply"
    if [[ -d "${battery_path}" ]]; then
        local bat
        for bat in "${battery_path}"/BAT* "${battery_path}"/battery*; do
            [[ -e "${bat}" ]] && return 0
        done
    fi
    return 1
}

# ── Inject laptop input config idempotently ───────────────────────────────────
_hardware_inject_laptop_input() {
    local src="${CONFIGS_DIR}/sway/input-laptop.conf"
    local marker="# sway-essentials: laptop-input"

    if [[ ! -f "${src}" ]]; then
        core_log_warn "Laptop input config not found: ${src}"
        return 0
    fi

    if [[ ! -f "${_SWAY_CONFIG}" ]]; then
        core_log_warn "Sway config not found at ${_SWAY_CONFIG}; skipping injection."
        return 0
    fi

    # Idempotency: skip if already injected
    if grep -qF "${marker}" "${_SWAY_CONFIG}"; then
        core_log_info "Laptop input config already present; skipping."
        return 0
    fi

    backup_file "${_SWAY_CONFIG}"

    {
        echo ""
        echo "${marker}"
        cat "${src}"
    } >> "${_SWAY_CONFIG}"

    core_log_info "Injected laptop input config into ${_SWAY_CONFIG}"
}

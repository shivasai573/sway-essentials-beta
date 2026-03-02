#!/usr/bin/env bash
# lib/power.sh — Power Management Profiles module.
# Prompts hardware profile and installs a lightweight power daemon.
# Sourced by install.sh; not executed directly.

module_power_profiles() {
    core_log_bold "── Power Management Profiles ─────────────────────────────"

    local profile
    profile="$(ui_choose "Select your hardware profile:" \
        "Desktop (no power management)" \
        "Modern Laptop (tlp)" \
        "Degraded Battery (auto-cpufreq)")" || true

    if [[ -z "${profile}" ]]; then
        core_log_info "Power profiles: cancelled."
        return 0
    fi

    case "${profile}" in
        "Desktop (no power management)")
            core_log_info "Desktop profile selected; no daemon installed."
            ;;
        "Modern Laptop (tlp)")
            _power_install_tlp
            ;;
        "Degraded Battery (auto-cpufreq)")
            _power_install_auto_cpufreq
            ;;
    esac

    core_log_info "Power management configuration complete."
}

# ── TLP ───────────────────────────────────────────────────────────────────────
_power_install_tlp() {
    core_log_info "Installing tlp…"
    packages_install tlp tlp-rdw

    if command -v systemctl &>/dev/null; then
        sudo systemctl enable --now tlp.service || core_log_warn "Could not enable tlp.service"
    fi

    core_log_info "tlp installed and enabled."
    # TODO: expose a minimal /etc/tlp.conf snippet for advanced tuning
}

# ── auto-cpufreq ──────────────────────────────────────────────────────────────
_power_install_auto_cpufreq() {
    core_log_info "Installing auto-cpufreq…"
    # auto-cpufreq is not always in distro repos; prefer pip or snap as fallback.
    if packages_is_installed auto-cpufreq; then
        core_log_info "auto-cpufreq already installed; skipping."
    else
        packages_install auto-cpufreq 2>/dev/null \
            || core_log_warn "auto-cpufreq not in distro repos; install manually: https://github.com/AdnanHodzic/auto-cpufreq"
    fi

    if command -v auto-cpufreq &>/dev/null; then
        sudo auto-cpufreq --install 2>/dev/null \
            || core_log_warn "auto-cpufreq --install failed; run manually with sudo."
    fi
    # TODO: write minimal auto-cpufreq.conf for degraded-battery scenario
}

#!/usr/bin/env bash
# install.sh — Sway Essentials TUI post-install wizard
# Entry point: sources modules, displays main menu, dispatches actions.
set -Eeuo pipefail

# ── Resolve script directory ─────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# ── Source modules ───────────────────────────────────────────────────────────
source "${SCRIPT_DIR}/lib/core.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/backup.sh"
source "${SCRIPT_DIR}/lib/packages.sh"
source "${SCRIPT_DIR}/lib/aesthetics.sh"
source "${SCRIPT_DIR}/lib/hardware.sh"
source "${SCRIPT_DIR}/lib/power.sh"
source "${SCRIPT_DIR}/lib/bundles.sh"
source "${SCRIPT_DIR}/lib/dotfiles.sh"

# ── Error & signal traps ─────────────────────────────────────────────────────
_on_error() {
    local exit_code=$?
    local line_no=${1:-?}
    core_log_error "Unexpected error on line ${line_no} (exit code ${exit_code})."
    core_log_warn  "Your system has NOT been modified beyond what was already applied."
    exit "${exit_code}"
}

_on_interrupt() {
    echo ""
    core_log_warn "Interrupted by user (CTRL+C). Exiting cleanly."
    exit 130
}

trap '_on_error ${LINENO}' ERR
trap '_on_interrupt'       INT TERM

# ── Full setup ───────────────────────────────────────────────────────────────
run_full_setup() {
    core_log_info "Starting full setup…"
    backup_create_snapshot

    module_aesthetics       || core_log_warn "Aesthetics module skipped/failed."
    module_hardware_tuning  || core_log_warn "Hardware module skipped/failed."
    module_power_profiles   || core_log_warn "Power module skipped/failed."
    module_app_bundles      || core_log_warn "Bundles module skipped/failed."
    module_custom_dotfiles  || core_log_warn "Dotfiles module skipped/failed."

    core_log_info "Full setup complete."
}

# ── Main menu ────────────────────────────────────────────────────────────────
main_menu() {
    while true; do
        local choice
        choice="$(ui_main_menu \
            "Run Full Setup" \
            "Aesthetic Engine" \
            "Hardware & Input Auto-Tuning" \
            "Power Management Profiles" \
            "Workflow App Bundles" \
            "Custom Dotfiles Integration" \
            "Restore Previous Configuration" \
            "Exit")"

        case "${choice}" in
            "Run Full Setup")                run_full_setup ;;
            "Aesthetic Engine")              module_aesthetics ;;
            "Hardware & Input Auto-Tuning")  module_hardware_tuning ;;
            "Power Management Profiles")     module_power_profiles ;;
            "Workflow App Bundles")          module_app_bundles ;;
            "Custom Dotfiles Integration")   module_custom_dotfiles ;;
            "Restore Previous Configuration") backup_restore_last ;;
            "Exit"|"")
                core_log_info "Goodbye."
                exit 0
                ;;
            *)
                core_log_warn "Unknown selection: '${choice}'"
                ;;
        esac
    done
}

# ── Entrypoint ───────────────────────────────────────────────────────────────
main() {
    core_check_dependencies
    core_log_info "Sway Essentials — post-install wizard (beta)"
    main_menu
}

main "$@"

#!/usr/bin/env bash
# lib/ui.sh — Reusable gum TUI wrappers.
# Sourced by install.sh; not executed directly.

# ── Guard: ensure gum is available ───────────────────────────────────────────
_ui_require_gum() {
    if ! command -v gum &>/dev/null; then
        core_log_error "gum is not installed. Please install it first:"
        core_log_error "  https://github.com/charmbracelet/gum#installation"
        exit 1
    fi
}

# ── Main menu ────────────────────────────────────────────────────────────────
# Usage: choice="$(ui_main_menu "Option A" "Option B" ...)"
# Returns the selected item text, or empty string if cancelled.
ui_main_menu() {
    _ui_require_gum
    gum choose \
        --header "✦ Sway Essentials — Main Menu" \
        --header.foreground="212" \
        --cursor.foreground="212" \
        "$@" || true
}

# ── Single-choice selection ───────────────────────────────────────────────────
# Usage: choice="$(ui_choose "Pick one:" "A" "B" "C")"
ui_choose() {
    _ui_require_gum
    local header="${1:?ui_choose: header required}"
    shift
    gum choose \
        --header "${header}" \
        --cursor.foreground="212" \
        "$@" || true
}

# ── Multi-select ─────────────────────────────────────────────────────────────
# Usage: selections="$(ui_multiselect "Pick many:" "A" "B" "C")"
# Returns newline-separated selected items.
ui_multiselect() {
    _ui_require_gum
    local header="${1:?ui_multiselect: header required}"
    shift
    gum choose \
        --no-limit \
        --header "${header}" \
        --cursor.foreground="212" \
        "$@" || true
}

# ── Confirm prompt ────────────────────────────────────────────────────────────
# Usage: if ui_confirm "Are you sure?"; then …; fi
# Returns 0 (yes) or 1 (no/cancelled).
ui_confirm() {
    _ui_require_gum
    local prompt="${1:-Are you sure?}"
    gum confirm "${prompt}"
}

# ── Spinner execution helper ──────────────────────────────────────────────────
# Usage: ui_spin "Doing thing…" some_function [args…]
# Runs the given command under a gum spinner; preserves exit code.
ui_spin() {
    _ui_require_gum
    local title="${1:?ui_spin: title required}"
    shift
    gum spin --spinner dot --title "${title}" -- "$@"
}

# ── Input prompt ──────────────────────────────────────────────────────────────
# Usage: value="$(ui_input "Enter URL:" "default")"
ui_input() {
    _ui_require_gum
    local prompt="${1:-Enter value:}"
    local placeholder="${2:-}"
    gum input \
        --prompt "${prompt} " \
        --placeholder "${placeholder}" \
        || true
}

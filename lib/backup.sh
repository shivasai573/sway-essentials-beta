#!/usr/bin/env bash
# lib/backup.sh — Non-destructive .graveyard backup & rollback model.
# Sourced by install.sh; not executed directly.

# ── Constants ─────────────────────────────────────────────────────────────────
_GRAVEYARD_BASE="${HOME}/.graveyard/sway-essentials"
_SNAPSHOT_DIR=""           # set by backup_create_snapshot
_TOUCHED_LIST=""           # newline-separated list of original paths backed up

# ── Create snapshot ───────────────────────────────────────────────────────────
# Call once at the start of a write session to initialise the snapshot dir.
backup_create_snapshot() {
    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"
    _SNAPSHOT_DIR="${_GRAVEYARD_BASE}-${timestamp}"
    mkdir -p "${_SNAPSHOT_DIR}"
    _TOUCHED_LIST=""
    core_log_info "Backup snapshot created: ${_SNAPSHOT_DIR}"
}

# ── Back up a single file ─────────────────────────────────────────────────────
# Usage: backup_file <path>
# Copies <path> into the current snapshot, mirroring the directory structure.
backup_file() {
    local original="${1:?backup_file: path required}"

    if [[ -z "${_SNAPSHOT_DIR}" ]]; then
        core_log_warn "No active snapshot — call backup_create_snapshot first. Skipping backup of ${original}."
        return 0
    fi

    if [[ ! -e "${original}" && ! -L "${original}" ]]; then
        return 0  # nothing to back up
    fi

    # Mirror path inside snapshot (strip leading /)
    local rel_path="${original#/}"
    local dest="${_SNAPSHOT_DIR}/${rel_path}"
    mkdir -p "$(dirname "${dest}")"

    if [[ -L "${original}" ]]; then
        # Preserve symlink
        cp -P "${original}" "${dest}"
    else
        cp -f "${original}" "${dest}"
    fi

    # Track the path for deterministic restore
    _TOUCHED_LIST="${_TOUCHED_LIST}${original}"$'\n'
    core_log_info "Backed up: ${original} → ${dest}"
}

# ── Restore last snapshot ─────────────────────────────────────────────────────
# Finds the most-recent snapshot directory and restores its contents.
backup_restore_last() {
    local graveyard_dir="${HOME}/.graveyard"
    local latest
    latest="$(find "${graveyard_dir}" -maxdepth 1 -name "sway-essentials-*" -type d 2>/dev/null \
        | sort | tail -n 1)" || true

    if [[ -z "${latest}" ]]; then
        core_log_warn "No backup snapshots found under ${graveyard_dir}/sway-essentials-*"
        return 0
    fi

    core_log_info "Restoring snapshot: ${latest}"

    if ! ui_confirm "Restore configuration from ${latest}?"; then
        core_log_info "Restore cancelled."
        return 0
    fi

    # Walk every file in the snapshot and restore it to its original path.
    while IFS= read -r -d '' backed_up; do
        # Reconstruct original absolute path
        local rel="${backed_up#"${latest}/"}"
        local original="/${rel}"
        mkdir -p "$(dirname "${original}")"
        cp -f "${backed_up}" "${original}"
        core_log_info "Restored: ${original}"
    done < <(find "${latest}" -type f -print0 2>/dev/null)

    core_log_info "Restore complete from: ${latest}"
}

# ── List snapshots ────────────────────────────────────────────────────────────
backup_list_snapshots() {
    local graveyard_dir="${HOME}/.graveyard"
    find "${graveyard_dir}" -maxdepth 1 -name "sway-essentials-*" -type d 2>/dev/null | sort || true
}

#!/usr/bin/env bash
# lib/dotfiles.sh — Custom Dotfiles Integration module.
# Clones a user-supplied dotfiles repo to a temp dir and applies safely.
# Sourced by install.sh; not executed directly.

module_custom_dotfiles() {
    core_log_bold "── Custom Dotfiles Integration ───────────────────────────"

    local repo_url
    repo_url="$(ui_input "Enter dotfiles git URL (leave blank to skip):" \
        "https://github.com/you/dotfiles.git")" || true

    if [[ -z "${repo_url}" ]]; then
        core_log_info "Dotfiles: skipped."
        return 0
    fi

    local dry_run=false
    local confirm_rc=0
    ui_confirm "Apply dotfiles to home directory? (No = dry-run only)" || confirm_rc=$?
    case "${confirm_rc}" in
        0) ;;  # Yes — apply normally
        1) dry_run=true
           core_log_info "Dry-run mode: files will be listed but not applied."
           ;;
        *) core_log_info "Dotfiles: cancelled."
           return 0
           ;;
    esac

    local tmp_dir
    tmp_dir="$(mktemp -d /tmp/sway-essentials-dotfiles.XXXXXX)"
    # shellcheck disable=SC2064
    trap "rm -rf '${tmp_dir}'" RETURN

    core_log_info "Cloning ${repo_url} → ${tmp_dir}"
    if ! git clone --depth 1 "${repo_url}" "${tmp_dir}"; then
        core_log_error "Failed to clone dotfiles repository: ${repo_url}"
        return 1
    fi

    _dotfiles_apply "${tmp_dir}" "${dry_run}"
    core_log_info "Dotfiles integration complete."
}

# ── Apply dotfiles ────────────────────────────────────────────────────────────
# Walks the cloned repo, backs up and symlinks every non-git file into $HOME.
_dotfiles_apply() {
    local src_dir="${1:?_dotfiles_apply: source dir required}"
    local dry_run="${2:-false}"

    find "${src_dir}" -not -path '*/.git/*' -not -name '.git' -type f | \
    while IFS= read -r file; do
        local rel="${file#"${src_dir}/"}"
        local dest="${HOME}/${rel}"

        if [[ "${dry_run}" == "true" ]]; then
            core_log_info "[dry-run] Would install: ${dest}"
        else
            backup_file "${dest}"
            mkdir -p "$(dirname "${dest}")"
            cp -f "${file}" "${dest}"
            core_log_info "Installed: ${dest}"
        fi
    done
    # TODO: support stow-style layout and executable install hooks
}

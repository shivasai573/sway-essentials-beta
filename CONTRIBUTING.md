# Contributing to Sway Essentials

Thank you for contributing! Please read this guide before opening a PR.

---

## Scope

Sway Essentials targets **Fedora only** (package manager: `dnf`).  
Do not introduce support for other distributions without prior discussion.

---

## Branch & PR Workflow

1. Fork the repository and create a **feature branch** from `main`:
   ```bash
   git checkout -b feat/short-description
   ```
2. Keep each branch focused on a single concern.
3. Open a pull request against `main` with a clear title and description.
4. All CI checks must pass before a PR can be merged.

---

## Commit Message Conventions

Use the [Conventional Commits](https://www.conventionalcommits.org/) style:

```
<type>(<scope>): <short summary>
```

| Type | When to use |
|------|-------------|
| `feat` | New feature or module |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `chore` | Maintenance (CI, deps, etc.) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests/smoke checks |

Examples:
```
feat(power): add auto-cpufreq profile selector
fix(backup): skip restore if snapshot dir is missing
docs(readme): add troubleshooting section
```

---

## Shell Safety Conventions

All shell scripts **must**:

- Start with `#!/usr/bin/env bash`.
- Set safety options at the top of every executed script:
  ```bash
  set -euo pipefail
  ```
  > Note: the entry-point `install.sh` additionally uses `-E` (ERR trap inheritance)
  > because it registers a custom `ERR` trap. Library scripts sourced by it inherit
  > the `-e`/`-u`/`-o pipefail` settings automatically.
- Quote all variable expansions (`"${var}"`, not `$var`).
- Be **idempotent** — running the script twice must not break anything or
  duplicate changes (guard with existence checks before writing).
- Use the project helpers (`core_safe_copy`, `core_safe_symlink`,
  `backup_file`) instead of raw `cp`/`ln` for any user-visible writes.
- Never store secrets, tokens, or passwords in scripts or config files.

ShellCheck must pass with `--severity=warning` before opening a PR.

---

## Running Local Checks Before a PR

```bash
# 1. Syntax-check all shell scripts
bash -n install.sh lib/*.sh

# 2. ShellCheck lint
shellcheck --severity=warning install.sh lib/*.sh

# 3. Verify expected config files are present
ls configs/sway/config configs/environment.d/wayland.conf \
   configs/rofi/catppuccin.rasi configs/rofi/nord.rasi \
   configs/waybar/minimal-top/config.jsonc \
   configs/waybar/floating-bottom/config.jsonc

# 4. Ensure install.sh is executable
chmod +x install.sh
```

All of the above are also enforced in CI.

---

## Questions?

Open an [issue](https://github.com/shivasai573/sway-essentials-beta/issues) before starting large changes.

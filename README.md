# Sway Essentials (beta)

A production-grade, modular TUI post-install wizard for the [Sway](https://swaywm.org/) window manager.

Sway Essentials helps you set up a beautiful, functional Sway environment quickly and safely — with non-destructive defaults and easy rollback.

---

## Features

- **Aesthetic Engine** — Apply Catppuccin or Nord colour themes to Waybar and Rofi from curated config templates.
- **Hardware & Input Auto-Tuning** — Automatically detects laptops and injects appropriate touchpad/keyboard settings.
- **Power Management Profiles** — Install and configure `tlp` or `auto-cpufreq` for your hardware.
- **Workflow App Bundles** — Multi-select bundles (Terminal Setup, Developer Core, Multimedia) and install in one step.
- **Custom Dotfiles Integration** — Clone your dotfiles repo and apply files safely (with dry-run mode).
- **Non-destructive Rollback** — Every write operation is backed up to `~/.graveyard/sway-essentials-<timestamp>/` before changes are made. Restore with one menu option.

---

## Prerequisites

| Tool  | Purpose                        | Install |
|-------|--------------------------------|---------|
| `bash` ≥ 5 | Shell runtime            | system package manager |
| `gum`  | TUI prompts and spinners       | [charmbracelet/gum](https://github.com/charmbracelet/gum#installation) |
| `git`  | Dotfiles cloning               | system package manager |
| `sudo` | Package installation           | system package manager |

> **Privileges**: The installer uses `sudo` only for package manager commands. All config writes go to `$HOME` and do not require root.

---

## Quick Start

```bash
# Clone the repo
git clone https://github.com/shivasai573/sway-essentials-beta.git
cd sway-essentials-beta

# Make the installer executable
chmod +x install.sh scripts/detect-pkg-manager.sh

# Run
./install.sh
```

The interactive main menu will guide you through available modules.

---

## Supported Package Managers

| Distro family | Package manager |
|---------------|----------------|
| Arch / Manjaro | `pacman` |
| Debian / Ubuntu | `apt` |
| Fedora / RHEL | `dnf` |
| openSUSE | `zypper` |

---

## Rollback Behaviour

Before any file is modified or created, the original is copied to:

```
~/.graveyard/sway-essentials-<YYYYMMDD_HHMMSS>/<original_path>
```

To restore, select **Restore Previous Configuration** from the main menu.  
The most recent snapshot is restored automatically.

Snapshots are never deleted by the installer — clean them up manually when no longer needed:

```bash
ls ~/.graveyard/
rm -rf ~/.graveyard/sway-essentials-20240101_120000
```

---

## Project Structure

```
install.sh                    # Entry point
lib/
  core.sh                     # Logging, safe copy/symlink helpers
  ui.sh                       # gum TUI wrappers
  backup.sh                   # .graveyard backup & restore
  packages.sh                 # Package manager abstraction
  aesthetics.sh               # Theme / Waybar / Rofi module
  hardware.sh                 # Laptop detection & input tuning
  power.sh                    # Power daemon installation
  bundles.sh                  # App bundle installation
  dotfiles.sh                 # Custom dotfiles integration
configs/
  sway/config                 # Base Sway config template
  sway/input-laptop.conf      # Laptop input overrides
  waybar/minimal-top/         # Minimal top bar layout
  waybar/floating-bottom/     # Floating bottom bar layout
  rofi/catppuccin.rasi        # Catppuccin Rofi theme
  rofi/nord.rasi              # Nord Rofi theme
  fonts/manifest.txt          # Recommended fonts
  wallpapers/                 # Place wallpapers here (not tracked by git)
scripts/
  detect-pkg-manager.sh       # Distro package manager detection
```

---

## Safety Notes

- **Non-destructive**: existing configs are always backed up before modification.
- **Idempotent**: operations such as laptop input injection will not be applied twice.
- **Dry-run support**: the dotfiles module can list changes without applying them.
- **CTRL+C safe**: the installer handles interrupts cleanly without leaving partial state.

---

## Beta Scope

This is an early beta. The following are working scaffolds and may have rough edges:

- Package lists per bundle are minimal starting points — extend them in `lib/bundles.sh`.
- Power daemon configuration beyond install is a TODO stub.
- Dotfiles apply uses a flat copy strategy; stow-style layouts are a future enhancement.

Contributions and bug reports welcome via [issues](https://github.com/shivasai573/sway-essentials-beta/issues).

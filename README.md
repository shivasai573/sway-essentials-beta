# Sway Essentials (beta)

A production-grade, modular TUI post-install wizard for the [Sway](https://swaywm.org/) window manager.

Sway Essentials helps you set up a beautiful, functional Sway environment quickly and safely — with non-destructive defaults and easy rollback.

---

## Supported Platform Matrix

| Distro | Version | Package Manager | Status |
|--------|---------|----------------|--------|
| Fedora | 39+ | `dnf` | ✅ Tested |
| Other | — | — | ❌ Not supported |

> **Fedora only.** The installer hard-codes `dnf` and Fedora package names.
> Running on other distributions will fail at the package installation step.

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

| Tool | Purpose | Install |
|------|---------|---------|
| `bash` ≥ 5 | Shell runtime | pre-installed on Fedora |
| `gum` | TUI prompts and spinners | [charmbracelet/gum](https://github.com/charmbracelet/gum#installation) |
| `git` | Dotfiles cloning | `sudo dnf install git` |
| `sudo` | Package installation | pre-installed on Fedora |

> ⚠️ **Privileged operations**: `sudo` is used only for `dnf install` commands.
> All configuration writes go to `$HOME` and never require root.
> Review `lib/packages.sh` if you want to audit exactly what gets installed before running.

---

## Quick Start

```bash
# Clone the repo
git clone https://github.com/shivasai573/sway-essentials-beta.git
cd sway-essentials-beta

# Make the installer executable
chmod +x install.sh

# Run
./install.sh
```

The interactive main menu will guide you through available modules.

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

### Manual Uninstall / Rollback

If you want to fully undo what Sway Essentials applied:

1. **Restore the latest backup** via the menu (`Restore Previous Configuration`), or manually:
   ```bash
   # Find the snapshot you want
   ls ~/.graveyard/
   # Copy files back (example)
   cp ~/.graveyard/sway-essentials-<timestamp>/home/<user>/.config/sway/config \
      ~/.config/sway/config
   ```

2. **Remove symlinks** created by the installer (Waybar, Rofi, Sway config, Wayland env):
   ```bash
   rm -f ~/.config/sway/config
   rm -f ~/.config/waybar/config.jsonc ~/.config/waybar/style.css
   rm -f ~/.config/rofi/catppuccin.rasi ~/.config/rofi/nord.rasi
   rm -f ~/.config/environment.d/wayland.conf
   ```

3. **Remove installed fonts** (optional):
   ```bash
   rm -rf ~/.local/share/fonts/JetBrainsMono
   fc-cache -f
   ```

4. **Remove installed packages** (optional — only if you want to uninstall them):
   ```bash
   sudo dnf remove waybar rofi-wayland swaybg fontawesome-fonts tlp auto-cpufreq
   ```

---

## Project Structure

```
install.sh                    # Entry point
lib/
  core.sh                     # Logging, safe copy/symlink helpers
  ui.sh                       # gum TUI wrappers
  backup.sh                   # .graveyard backup & restore
  packages.sh                 # Package manager abstraction & detection
  aesthetics.sh               # Theme / Waybar / Rofi module
  hardware.sh                 # Laptop detection & input tuning
  power.sh                    # Power daemon installation
  bundles.sh                  # App bundle installation
  dotfiles.sh                 # Custom dotfiles integration
configs/
  environment.d/wayland.conf  # Wayland environment variables for systemd user session
  sway/config                 # Base Sway config template
  sway/input-laptop.conf      # Laptop input overrides
  waybar/minimal-top/         # Minimal top bar layout
  waybar/floating-bottom/     # Floating bottom bar layout
  rofi/catppuccin.rasi        # Catppuccin Rofi theme
  rofi/nord.rasi              # Nord Rofi theme
  fonts/manifest.txt          # Recommended fonts
  wallpapers/                 # Place wallpapers here (not tracked by git)
```

### Files & Configs Touched

| Config File | Where It Goes | How |
|-------------|--------------|-----|
| `configs/sway/config` | `~/.config/sway/config` | symlink |
| `configs/sway/input-laptop.conf` | appended to `~/.config/sway/config` | injected (idempotent) |
| `configs/waybar/<layout>/config.jsonc` | `~/.config/waybar/config.jsonc` | symlink |
| `configs/waybar/<layout>/style.css` | `~/.config/waybar/style.css` | symlink |
| `configs/rofi/<theme>.rasi` | `~/.config/rofi/<theme>.rasi` | symlink |
| `configs/environment.d/wayland.conf` | `~/.config/environment.d/wayland.conf` | symlink |
| JetBrainsMono Nerd Font | `~/.local/share/fonts/JetBrainsMono/` | downloaded & extracted |

Every pre-existing file is backed up to `~/.graveyard/` before being replaced.

---

## Troubleshooting

### Wayland environment variables not taking effect

The file `~/.config/environment.d/wayland.conf` is read by `systemd --user` at
login time. Changes only apply after you **log out and log back in**.

```bash
# Verify the symlink exists
ls -la ~/.config/environment.d/wayland.conf

# Check what variables are set
cat ~/.config/environment.d/wayland.conf

# Force a reload of the user session environment (requires re-login to fully apply)
systemctl --user daemon-reload
```

### Fonts not showing in apps after installation

Run `fc-cache` to rebuild the font cache:

```bash
fc-cache -f -v
```

Then restart the affected application. If using Waybar or Rofi, reload Sway:

```bash
swaymsg reload
```

### Sway config changes not applied

After any config change, reload the running Sway session:

```bash
swaymsg reload
```

If `swaymsg` is not available or the session is not running, log out and back in
to start a fresh Sway session with the updated config.

### Script fails with "Missing required tools"

Install `gum` before running the installer:

```bash
# Via Go (requires Go ≥ 1.21)
go install github.com/charmbracelet/gum@latest

# Or via Copr (Fedora)
sudo dnf copr enable charmbracelet/tap
sudo dnf install gum
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

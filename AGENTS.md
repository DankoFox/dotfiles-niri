# AGENTS.md — Repository Instructions for AI Agents (OpenCode, AGY, etc.)

Welcome! This repository contains the personal dotfiles for an **Arch Linux / EndeavourOS** system running the **Niri** scrollable-tiling Wayland compositor.

All AI coding assistants (including **OpenCode**, **Antigravity CLI (agy)**, and others) must follow the architecture and operational conventions defined in this file.

---

## 1. System & Architecture Overview

- **Distribution**: Arch Linux / EndeavourOS
- **Compositor**: Niri (scrollable-tiling Wayland compositor) + `xwayland-satellite`
- **Dotfiles Manager**: GNU Stow (`stow -v -R -t ~ .`)
- **Display Manager**: `ly` (TUI display manager via `ly@tty2.service`)
- **Core Stack**:
  - Terminal: Kitty (`~/.config/kitty/`)
  - Shell: Zsh + Starship prompt (`~/.zshrc`, `~/.aliases`, `~/.config/starship.toml`)
  - Launcher: Fuzzel (`~/.config/fuzzel/`)
  - Status Bar: Waybar (`~/.config/waybar/`)
  - Editor: Neovim (`~/.config/nvim/`)
  - File Manager: Nemo (`~/.config/nemo/`)
  - Input Method (IME): Fcitx5 with Bamboo engine (`~/.config/fcitx5/`, `~/.config/environment.d/`)

---

## 2. Repository Layout

```
~/.dotfiles/
├── AGENTS.md               # Standing instructions for AI agents (ignored by Stow)
├── README.md               # User documentation (ignored by Stow)
├── bootstrap.sh            # One-click bootstrap script for fresh installs (ignored by Stow)
├── .stow-local-ignore      # Regex patterns of files NOT to symlink into $HOME
├── .aliases                # Shell aliases -> symlinked to ~/.aliases
├── .zshrc                  # Shell configuration -> symlinked to ~/.zshrc
├── packages/               # Source of truth for all system packages (ignored by Stow)
│   ├── pacman.txt          # Native Arch / EndeavourOS official packages
│   └── aur.txt             # Arch User Repository (AUR) packages
├── scripts/                # Helper utilities (ignored by Stow)
│   └── check-packages.sh   # Audits installed vs tracked packages
└── .config/                # Config directories -> symlinked into ~/.config/
    ├── environment.d/      # Systemd user environment configs (e.g. 10-fcitx.conf)
    ├── fcitx5/             # Fcitx5 IME settings and profiles
    ├── fuzzel/             # Application launcher
    ├── hypr/               # Screen locker (hyprlock.conf)
    ├── kitty/              # Kitty terminal emulator
    ├── mako/               # Notification daemon (config)
    ├── nemo/               # Nemo file manager
    ├── niri/               # Modular Niri compositor configuration
    ├── nvim/               # Neovim configuration
    ├── starship.toml       # Starship shell prompt
    └── waybar/             # Waybar status bar
```

---

## 3. Strict Rules & Conventions for AI Agents

### A. Package Management
1. **Never install packages untracked**: If a task requires a new package, **always** record it in the proper file:
   - Official repos (core, extra, multilib, endeavouros): Add to `packages/pacman.txt`.
   - Arch User Repository: Add to `packages/aur.txt`.
2. **Package File Format**: Follow the existing format (`<package-name> # <brief description>`).
3. **Verify with `check-packages.sh`**: Run `./scripts/check-packages.sh` to ensure package lists match local system state.

### B. Niri Configuration (`.config/niri/`)
1. **Modular Architecture**:
   - `config.kdl` is the entry point and includes all sub-configs:
     - `environment.kdl`: Session environment variables (`environment { ... }`).
     - `autostart.kdl`: Daemons and background processes (`spawn-at-startup`).
     - `binds.kdl`: Keyboard shortcuts and mouse bindings.
     - `input.kdl`: Keyboard layout, touchpad, and mouse settings.
     - `layout.kdl`: Window sizing, borders, column widths, gaps.
     - `rules.kdl`: Window placement rules (`window-rule { ... }`).
     - `misc.kdl`: Display monitor outputs and cursor themes.
2. **Validation Requirement**:
   - **Always** run `niri validate -c ~/.dotfiles/.config/niri/config.kdl` after making any change to any `.kdl` file.
   - Never consider a Niri edit complete if `niri validate` fails or outputs errors.

### C. Wayland & Input Method Guidelines
1. **Vietnamese IME**: The system uses `fcitx5-bamboo` as the standard Vietnamese input method engine.
2. **Wayland Environment Variables**:
   - `XMODIFIERS=@im=fcitx`
   - `QT_IM_MODULE=fcitx`
   - `SDL_IM_MODULE=fcitx`
   - `ELECTRON_OZONE_PLATFORM_HINT=auto`
   - **Do NOT set `GTK_IM_MODULE=fcitx` globally**: GTK 3/4 applications must communicate with Fcitx5 via native Wayland `text-input-v3` protocol to prevent crashes and deadlocks.
3. **Window Floating**: Dialogs, popups, and configuration tools for Fcitx5 or Polkit must have `open-floating true` in `rules.kdl`.

### D. GNU Stow & Symlink Safety
1. **Root Files**: Any script, documentation, or tooling added directly to the repository root that should **not** appear in `$HOME` **must** be listed in `.stow-local-ignore`.
2. **Stow Testing**: Test Stow symlinking with dry-run mode first if adding new top-level directories:
   ```bash
   stow -n -v -R -t ~ .
   ```
3. To apply symlinks:
   ```bash
   stow -v -R -t ~ .
   ```

### E. Scripting Standards (`*.sh`)
- Use `#!/usr/bin/env bash` with `set -euo pipefail`.
- Keep existing color-coded logger functions (`log_info`, `log_success`, `log_warn`, `log_error`).
- Maintain idempotency: scripts should be safe to run multiple times without causing duplicates or errors.

---

## 4. Quick Verification Commands

```bash
# Validate Niri compositor configuration
niri validate -c ~/.dotfiles/.config/niri/config.kdl

# Re-link dotfiles via GNU Stow
stow -v -R -t ~ .

# Audit package status (tracked vs installed)
~/.dotfiles/scripts/check-packages.sh

# Run full bootstrap process
./bootstrap.sh
```

---

## 5. Niri Setup Roadmap & TODO List

Progressively expanding and refining the Niri desktop environment. Work through these items one-by-one:

- [x] **1. Clipboard History Integration (`cliphist` + Fuzzel)**
  - Autostarted (`wl-paste --watch cliphist store` for text & images) in `autostart.kdl`.
  - Added toggle Fuzzel picker (`Alt+V`) in `binds.kdl` invoking `~/.config/fuzzel/cliphist-picker.sh` (with image previews & wide layout).

- [x] **2. Idle Management Daemon (`hypridle`)**
  - Companion daemon to `hyprlock` for idle timeouts and power management.
  - Configured in `~/.config/hypr/hypridle.conf` with balanced stages:
    - 2.5 min (150s): Dim screen backlight to 10% (safe for both desktop & laptop).
    - 5 min (300s): Lock session via `hyprlock`.
    - 6 min (360s): Turn off displays via `niri msg action power-off-monitors`.
    - 30 min (1800s): Suspend PC (`systemctl suspend`).
  - Tracked in `packages/pacman.txt`, autostarted in `autostart.kdl`.

- [x] **3. Notification Daemon (`mako`)**
  - Lightweight Wayland notification daemon with Gruvbox Dark Soft palette and Iosevka Nerd Font.
  - Track `mako` in `packages/pacman.txt`, configure `~/.config/mako/config`, autostart in `autostart.kdl`.

- [x] **4. Wallpaper Daemon (`awww`)**
  - High-performance, animated Wayland wallpaper daemon (`awww`).
  - Tracked `awww` in `packages/pacman.txt`, autostarted via `~/.config/waybar/scripts/init-wallpaper.sh` in `autostart.kdl`.
  - Added dedicated Waybar `custom/wallpaper` module with left-click non-repeating random cycle (`cycle-wallpaper.sh`) and right-click Fuzzel thumbnail picker (`wallpaper-picker.sh`).
  - Separated wallpaper actions from `backlight` module so both desktop (where backlight is absent) and laptop work seamlessly.

- [x] **5. Niri Window Rules Polish (`rules.kdl`)**
  - Set `open-floating true` and `block-out-from "screencast"` for Polkit authentication prompts (`polkit-gnome-authentication-agent-1`).
  - Set `open-floating true` with fixed initial geometries for `pavucontrol` and `gnome-disk-utility`.
  - Added floating rules for Zen Browser Picture-in-Picture, Nemo dialogs (properties, conflicts, file operations), GTK portal file choosers, and Feh.
  - Removed obsolete WezTerm and Firefox rules to match Kitty and Zen Browser stack.

- [x] **6. Volume & Backlight On-Screen Display (`swayosd`)**
  - Clean OSD bubbles for volume, mute, brightness, and caps lock changes.
  - Tracked `swayosd` in `packages/pacman.txt` (official extra repo).
  - Configured Gruvbox Dark Soft theme in `~/.config/swayosd/style.css`.
  - Wired media and CapsLock keys in `binds.kdl`, autostarted `swayosd-server` in `autostart.kdl`.

- [x] **7. Night Light / Blue Light Filter (`wlsunset`)**
  - Automatic gamma temperature transition at sunrise/sunset (Ho Chi Minh City: Lat 10.8, Lon 106.6, 4000K nighttime temp).
  - Tracked `wlsunset` in `packages/pacman.txt`, autostarted in `autostart.kdl`.
  - Added toggle script `~/.config/niri/toggle-nightlight.sh` (cycles Auto -> Day -> Night with Mako notifications) bound to `Mod+N` in `binds.kdl`.

- [x] **8. Wayland Power / Logout Menu (`wlogout`)**
  - Fullscreen lock/logout/reboot/shutdown/suspend/hibernate menu with Gruvbox Dark Soft styling and custom SVGs.
  - Tracked in `packages/aur.txt`, configured in `~/.config/wlogout/` (`layout`, `style.css`, `icons/`).
  - Consolidated Waybar poweroff/suspend buttons into single `custom/power` module.
  - Bound to `Mod+Shift+E` and `Ctrl+Alt+Delete` in `binds.kdl`.

- [ ] **9. Screenshot Annotation Tool (`swappy`)**
  - Pipe Niri screenshots into Swappy for instant arrows, cropping, and text before saving.
  - Track `swappy` in `packages/pacman.txt`, integrate into screenshot keybinds.


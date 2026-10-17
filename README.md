# Dotfiles (Niri + Wayland on Arch / EndeavourOS)

My personal dotfiles for Arch Linux / EndeavourOS featuring the **Niri** scrollable-tiling Wayland compositor, **Kitty**, **Waybar**, **Fuzzel**, **Neovim**, and **Zsh**. Managed cleanly with **GNU Stow**.

---

## 🚀 Quick Bootstrap on a Fresh Machine

On a fresh EndeavourOS or Arch Linux installation:

```bash
# 1. Clone dotfiles repository
git clone git@github.com:DankoFox/dotfiles-niri.git ~/.dotfiles
# Or using HTTPS if SSH key is not set up yet:
# git clone https://github.com/DankoFox/dotfiles-niri.git ~/.dotfiles

# 2. Enter directory and run bootstrap script
cd ~/.dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

### What `bootstrap.sh` does automatically:
1. **Package Databases & System Upgrade**: Synchronizes pacman repositories, updates keyrings, and performs a full system upgrade (`pacman -Syu`) to prevent library ABI version mismatches.
2. **AUR Helper**: Detects `paru` (or `yay`). If missing, installs/builds `paru` automatically.
3. **Package Installation**: Installs all official repository packages (`packages/pacman.txt`) and AUR packages (`packages/aur.txt`).
4. **Shell Setup**: Sets default shell to `zsh` and installs `zsh-autosuggestions` and `zsh-syntax-highlighting` into `~/.zsh/`.
5. **System Services**: Enables `earlyoom.service` (out-of-memory prevention), `ly@tty2.service` (TUI display manager), and `paccache.timer`.
6. **GNU Stow**: Safely backs up any conflicting default skeleton files and symlinks all configs into `$HOME`.

---

## 📦 Package Management

Packages are split into two plain-text files inside `packages/`:

- **[`packages/pacman.txt`](packages/pacman.txt)**: Official repository packages (Compositor, terminal, CLI tools, fonts, development).
- **[`packages/aur.txt`](packages/aur.txt)**: AUR packages (`zen-browser-bin`, `vesktop-bin`, `bibata-cursor-theme-bin`).

### Tracking newly installed packages:
Whenever you install something new, check if it's tracked:
```bash
dotfiles-check
# Or directly: ~/.dotfiles/scripts/check-packages.sh
```
This tool checks `pacman` and `paru` against your dotfiles and offers to automatically track newly installed AUR or native packages!

---

## 📂 Repository Structure

```
~/.dotfiles/
├── .aliases                # Shell aliases (eza, pacman, git, dotfiles)
├── .zshrc                  # Zsh configuration (history, starship, fzf, zoxide)
├── .config/
│   ├── fuzzel/             # Application launcher
│   ├── kitty/              # Terminal emulator
│   ├── nemo/               # File manager configuration
│   ├── niri/               # Niri window manager & keybindings
│   ├── nvim/               # Neovim (Kickstart config)
│   ├── starship.toml       # Prompt theme
│   └── waybar/             # Waybar status bar config & styling
├── packages/
│   ├── pacman.txt          # List of official Arch/Endeavour packages
│   └── aur.txt             # List of AUR packages
├── scripts/
│   └── check-packages.sh   # Package tracking & audit script
├── bootstrap.sh            # One-click bootstrap script for fresh installs
└── .stow-local-ignore      # Prevents non-dotfile repository files from being symlinked
```

---

## 🛠️ Helpful Aliases

| Alias | Command | Description |
| :--- | :--- | :--- |
| `dotfiles` | `cd ~/.dotfiles` | Jump to dotfiles folder |
| `dotfiles-check`| `~/.dotfiles/scripts/check-packages.sh` | Audit installed vs tracked packages |
| `dotfiles-stow` | `cd ~/.dotfiles && stow -v -R -t ~ .` | Re-stow all dotfiles |
| `pac` | `sudo pacman -S` | Install package |
| `pacu` | `sudo pacman -Syu` | Full system update |
| `lg` | `lazygit` | Launch Lazygit TUI |

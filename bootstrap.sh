#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Bootstrap Script for Arch Linux / EndeavourOS + Niri
# ==============================================================================
# Usage:
#   cd ~/.dotfiles
#   ./bootstrap.sh
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="${DOTFILES_DIR}/packages"
PACMAN_FILE="${PACKAGES_DIR}/pacman.txt"
AUR_FILE="${PACKAGES_DIR}/aur.txt"

# ANSI Colors for formatted output
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

log_info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET} $*"; }
log_success() { echo -e "${GREEN}${BOLD}[OK]${RESET} $*"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET} $*"; }
log_error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $*"; }

echo -e "${BOLD}====================================================${RESET}"
echo -e "${BOLD}   Bootstrapping EndeavourOS / Arch + Niri Setup     ${RESET}"
echo -e "${BOLD}====================================================${RESET}"
echo ""

# ------------------------------------------------------------------------------
# 1. Environment & Sudo Validation
# ------------------------------------------------------------------------------
log_info "Checking environment and root privileges..."
if [ ! -f /etc/arch-release ]; then
    log_error "This script is designed for Arch Linux / EndeavourOS."
    exit 1
fi

sudo -v
# Keep-alive: update existing `sudo` timestamp until the script finishes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ------------------------------------------------------------------------------
# 2. Update Package Databases, Keyrings & System Upgrade
# ------------------------------------------------------------------------------
log_info "Synchronizing pacman package databases and updating keyrings..."
sudo pacman -Sy --noconfirm archlinux-keyring 2>/dev/null || true
if pacman -Qq endeavouros-keyring >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm endeavouros-keyring 2>/dev/null || true
fi

# Prevent partial upgrades and library ABI version mismatches (e.g. Qt6)
log_info "Performing full system upgrade to maintain library consistency..."
sudo pacman -Syu --noconfirm

# Ensure base-devel and git are installed
log_info "Ensuring base-devel and git are present..."
sudo pacman -S --needed --noconfirm base-devel git stow

# ------------------------------------------------------------------------------
# 3. Detect or Install AUR Helper (paru / yay)
# ------------------------------------------------------------------------------
AUR_HELPER=""
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
else
    log_warn "No AUR helper found. Attempting to install paru..."
    if sudo pacman -S --needed --noconfirm paru 2>/dev/null; then
        AUR_HELPER="paru"
    else
        log_info "Building paru-bin from AUR..."
        TMP_DIR="$(mktemp -d)"
        git clone https://aur.archlinux.org/paru-bin.git "${TMP_DIR}/paru-bin"
        (cd "${TMP_DIR}/paru-bin" && makepkg -si --noconfirm)
        rm -rf "${TMP_DIR}"
        AUR_HELPER="paru"
    fi
fi
log_success "AUR helper ready: ${AUR_HELPER}"

# ------------------------------------------------------------------------------
# 4. Install Native Pacman Packages
# ------------------------------------------------------------------------------
if [ -f "${PACMAN_FILE}" ]; then
    log_info "Reading pacman package list from ${PACMAN_FILE}..."
    mapfile -t PACMAN_PKGS < <(grep -vE '^\s*#|^\s*$' "${PACMAN_FILE}" | awk '{print $1}')
    if [ ${#PACMAN_PKGS[@]} -gt 0 ]; then
        log_info "Installing ${#PACMAN_PKGS[@]} official pacman packages..."
        sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
        log_success "Pacman packages installed successfully."
    fi
else
    log_warn "Pacman package list not found at ${PACMAN_FILE}."
fi

# ------------------------------------------------------------------------------
# 5. Install AUR Packages
# ------------------------------------------------------------------------------
if [ -f "${AUR_FILE}" ]; then
    log_info "Reading AUR package list from ${AUR_FILE}..."
    mapfile -t AUR_PKGS < <(grep -vE '^\s*#|^\s*$' "${AUR_FILE}" | awk '{print $1}')
    if [ ${#AUR_PKGS[@]} -gt 0 ]; then
        log_info "Installing ${#AUR_PKGS[@]} AUR packages using ${AUR_HELPER}..."
        "${AUR_HELPER}" -S --needed --noconfirm "${AUR_PKGS[@]}"
        log_success "AUR packages installed successfully."
    fi
else
    log_warn "AUR package list not found at ${AUR_FILE}."
fi

# ------------------------------------------------------------------------------
# 6. Setup Shell (Zsh) and Plugins
# ------------------------------------------------------------------------------
log_info "Configuring default shell and zsh plugins..."
ZSH_PATH="$(which zsh 2>/dev/null || echo "/usr/bin/zsh")"

if ! grep -q "^${ZSH_PATH}$" /etc/shells; then
    log_info "Adding ${ZSH_PATH} to /etc/shells..."
    echo "${ZSH_PATH}" | sudo tee -a /etc/shells
fi

CURRENT_USER="$(id -un)"
CURRENT_SHELL="$(getent passwd "${CURRENT_USER}" | cut -d: -f7)"

if [ "${CURRENT_SHELL}" != "${ZSH_PATH}" ]; then
    log_info "Changing login shell to ${ZSH_PATH} for user ${CURRENT_USER}..."
    chsh -s "${ZSH_PATH}" "${CURRENT_USER}" || sudo usermod -s "${ZSH_PATH}" "${CURRENT_USER}"
    log_success "Shell set to zsh."
else
    log_success "Zsh is already the default shell."
fi

# Clone Zsh Plugins into ~/.zsh/
mkdir -p "${HOME}/.zsh"
if [ ! -d "${HOME}/.zsh/zsh-autosuggestions" ]; then
    log_info "Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.zsh/zsh-autosuggestions"
else
    log_success "zsh-autosuggestions is already installed."
fi

if [ ! -d "${HOME}/.zsh/zsh-syntax-highlighting" ]; then
    log_info "Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${HOME}/.zsh/zsh-syntax-highlighting"
else
    log_success "zsh-syntax-highlighting is already installed."
fi

# ------------------------------------------------------------------------------
# 7. Enable Systemd Services
# ------------------------------------------------------------------------------
log_info "Enabling essential system services..."

# earlyoom (Early OOM prevention)
if systemctl list-unit-files earlyoom.service >/dev/null 2>&1; then
    sudo systemctl enable --now earlyoom.service
    log_success "earlyoom.service enabled and started."
fi

# paccache.timer (cleanup unused pacman caches weekly)
if systemctl list-unit-files paccache.timer >/dev/null 2>&1; then
    sudo systemctl enable --now paccache.timer
    log_success "paccache.timer enabled."
fi

# ly Display Manager
if systemctl list-unit-files ly@.service >/dev/null 2>&1; then
    sudo systemctl enable ly@tty2.service
    log_success "ly@tty2.service enabled for display management."
elif systemctl list-unit-files ly.service >/dev/null 2>&1; then
    sudo systemctl enable ly.service
    log_success "ly.service enabled for display management."
fi

# ------------------------------------------------------------------------------
# 8. Deploy Dotfiles with GNU Stow
# ------------------------------------------------------------------------------
log_info "Preparing and linking dotfiles with GNU Stow..."

# Function to back up existing unlinked targets before stow
backup_if_conflict() {
    local target="$1"
    if [ -e "${target}" ] && [ ! -L "${target}" ]; then
        local backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
        log_warn "Backing up existing ${target} -> ${backup}"
        mv "${target}" "${backup}"
    fi
}

mkdir -p "${HOME}/.config"

# Check standard conflicting files
backup_if_conflict "${HOME}/.zshrc"
backup_if_conflict "${HOME}/.aliases"

# Check entries in .dotfiles/.config
if [ -d "${DOTFILES_DIR}/.config" ]; then
    for item in "${DOTFILES_DIR}/.config"/*; do
        [ -e "${item}" ] || continue
        name="$(basename "${item}")"
        backup_if_conflict "${HOME}/.config/${name}"
    done
fi

cd "${DOTFILES_DIR}"
stow -v -R -t "${HOME}" .
log_success "Dotfiles linked successfully via Stow."

echo ""
echo -e "${GREEN}${BOLD}====================================================${RESET}"
echo -e "${GREEN}${BOLD}             Bootstrap Complete!                    ${RESET}"
echo -e "${GREEN}${BOLD}====================================================${RESET}"
echo -e "Next steps:"
echo -e " 1. Log out or reboot to start your new ${BOLD}Niri${RESET} session via ${BOLD}ly${RESET}."
echo -e " 2. If you install new packages in the future, add them to ${BOLD}packages/pacman.txt${RESET} or ${BOLD}packages/aur.txt${RESET}."
echo ""

#!/usr/bin/env bash
# ==============================================================================
# Helper Script to Audit & Sync Installed Packages with Dotfiles
# ==============================================================================
# Shows which packages are installed on this machine but not yet tracked in
# packages/pacman.txt or packages/aur.txt, and vice versa.
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACMAN_FILE="${DOTFILES_DIR}/packages/pacman.txt"
AUR_FILE="${DOTFILES_DIR}/packages/aur.txt"

BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

echo -e "${BOLD}=== Dotfiles Package Audit ===${RESET}\n"

# Helper to read tracked packages
read_tracked() {
    local file="$1"
    if [ -f "$file" ]; then
        grep -vE '^\s*#|^\s*$' "$file" | awk '{print $1}' | sort -u
    fi
}

TRACKED_PACMAN=($(read_tracked "${PACMAN_FILE}"))
TRACKED_AUR=($(read_tracked "${AUR_FILE}"))

INSTALLED_NATIVE=($(pacman -Qqen | sort -u))
INSTALLED_AUR=($(pacman -Qqem | sort -u))

# ------------------------------------------------------------------------------
# 1. Audit AUR Packages
# ------------------------------------------------------------------------------
echo -e "${BOLD}[1] AUR Packages Audit:${RESET}"
UNTRACKED_AUR=()
for pkg in "${INSTALLED_AUR[@]}"; do
    if [[ ! " ${TRACKED_AUR[*]} " =~ " ${pkg} " ]]; then
        UNTRACKED_AUR+=("${pkg}")
    fi
done

if [ ${#UNTRACKED_AUR[@]} -gt 0 ]; then
    echo -e "${YELLOW}  Found ${#UNTRACKED_AUR[@]} untracked AUR package(s):${RESET}"
    for pkg in "${UNTRACKED_AUR[@]}"; do
        echo -e "    ${YELLOW}+ ${pkg}${RESET}"
    done
    read -rp "  Would you like to append these to packages/aur.txt? [y/N]: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        for pkg in "${UNTRACKED_AUR[@]}"; do
            echo "${pkg}" >> "${AUR_FILE}"
        done
        echo -e "  ${GREEN}Added to packages/aur.txt!${RESET}"
    fi
else
    echo -e "  ${GREEN}All installed AUR packages are tracked in packages/aur.txt.${RESET}"
fi
echo ""

# ------------------------------------------------------------------------------
# 2. Check for Tracked Packages Missing Locally
# ------------------------------------------------------------------------------
echo -e "${BOLD}[2] Tracked Packages Missing on This Machine:${RESET}"
MISSING_LOCAL=()
for pkg in "${TRACKED_PACMAN[@]}"; do
    if ! pacman -Q "${pkg}" >/dev/null 2>&1; then
        MISSING_LOCAL+=("pacman: ${pkg}")
    fi
done

for pkg in "${TRACKED_AUR[@]}"; do
    if ! pacman -Q "${pkg}" >/dev/null 2>&1; then
        MISSING_LOCAL+=("aur: ${pkg}")
    fi
done

if [ ${#MISSING_LOCAL[@]} -gt 0 ]; then
    echo -e "${YELLOW}  The following tracked packages are NOT installed on this machine:${RESET}"
    for item in "${MISSING_LOCAL[@]}"; do
        echo -e "    ${YELLOW}- ${item}${RESET}"
    done
    echo -e "  Run ${CYAN}./bootstrap.sh${RESET} to install all missing packages."
else
    echo -e "  ${GREEN}All tracked packages are currently installed locally!${RESET}"
fi
echo ""

echo -e "${BLUE}${BOLD}[INFO]${RESET} To add a new package manually, just edit ${CYAN}packages/pacman.txt${RESET} or ${CYAN}packages/aur.txt${RESET} and commit changes."

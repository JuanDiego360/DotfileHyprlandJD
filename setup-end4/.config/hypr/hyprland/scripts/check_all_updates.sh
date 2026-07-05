#!/usr/bin/env bash

# Count pacman updates
if command -v checkupdates &> /dev/null; then
    pacman_count=$(checkupdates 2>/dev/null | wc -l)
else
    pacman_count=0
fi

# Count AUR updates
if command -v yay &> /dev/null; then
    aur_count=$(yay -Qua 2>/dev/null | wc -l)
else
    aur_count=0
fi

# Count Flatpak updates
if command -v flatpak &> /dev/null; then
    flatpak_count=$(flatpak remote-ls --updates --app 2>/dev/null | wc -l)
else
    flatpak_count=0
fi

echo "$pacman_count $aur_count $flatpak_count"

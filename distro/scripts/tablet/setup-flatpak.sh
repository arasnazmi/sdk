#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

APPS=(
    net.nokyan.Resources
    org.gnome.World.Secrets
    com.github.tchx84.Flatseal
)

flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

for app in "${APPS[@]}"; do
    if flatpak info --system "${app}" >/dev/null 2>&1; then
        echo "Flatpak app already installed (from cache): ${app}"
    else
        echo "Installing Flatpak app: ${app}"
        flatpak install --system --noninteractive flathub "${app}"
    fi
done

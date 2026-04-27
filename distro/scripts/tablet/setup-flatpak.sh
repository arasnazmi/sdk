#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --system --noninteractive flathub net.nokyan.Resources
flatpak install --system --noninteractive flathub org.gnome.World.Secrets

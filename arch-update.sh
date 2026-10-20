#!/usr/bin/env bash
# Actualización periódica en Arch Linux.
set -euo pipefail

log() { printf '\n==> %s\n' "$*"; }

log "Actualizando repositorios oficiales"
sudo pacman -Syu --noconfirm

if command -v yay >/dev/null 2>&1; then
  log "Actualizando AUR (yay)"
  yay -Syu --noconfirm
fi

if command -v flatpak >/dev/null 2>&1; then
  log "Actualizando Flatpak"
  flatpak update -y
fi

log "Limpiando caché de pacman"
sudo pacman -Sc --noconfirm

log "Hecho."

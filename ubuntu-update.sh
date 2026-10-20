#!/usr/bin/env bash
# Actualización periódica en Ubuntu.
set -euo pipefail

log() { printf '\n==> %s\n' "$*"; }

log "Actualizando APT"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean

log "Actualizando snaps"
sudo snap refresh

if command -v flatpak >/dev/null 2>&1; then
  log "Actualizando Flatpak"
  flatpak update -y
fi

log "Hecho."

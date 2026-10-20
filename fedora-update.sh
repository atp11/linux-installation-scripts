#!/usr/bin/env bash
# Actualización periódica en Fedora.
set -euo pipefail

log() { printf '\n==> %s\n' "$*"; }

log "Actualizando DNF"
sudo dnf -y upgrade
sudo dnf -y autoremove
sudo dnf -y clean all

if command -v flatpak >/dev/null 2>&1; then
  log "Actualizando Flatpak"
  flatpak update -y
fi

log "Hecho."

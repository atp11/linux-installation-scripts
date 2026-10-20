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

if [[ -x "${HOME}/.venvs/default/bin/pip" ]]; then
  log "Actualizando paquetes del venv"
  # shellcheck disable=SC1091
  source "${HOME}/.venvs/default/bin/activate"
  pip install --upgrade pip
  pip list --outdated --format=columns 2>/dev/null | awk 'NR>2 {print $1}' \
    | xargs -r pip install -U || true
  deactivate
fi

log "Limpiando caché de pacman"
sudo pacman -Sc --noconfirm

log "Hecho."

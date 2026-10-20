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

if [[ -x "${HOME}/.venvs/default/bin/pip" ]]; then
  log "Actualizando paquetes del venv"
  # shellcheck disable=SC1091
  source "${HOME}/.venvs/default/bin/activate"
  pip install --upgrade pip
  pip list --outdated --format=columns 2>/dev/null | awk 'NR>2 {print $1}' \
    | xargs -r pip install -U || true
  deactivate
fi

log "Hecho."

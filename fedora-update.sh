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

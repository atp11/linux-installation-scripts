#!/usr/bin/env bash
# Post-install setup for Arch Linux (y derivados basados en pacman).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

if [[ "${EUID}" -eq 0 ]]; then
  warn "No ejecutes este script como root. Usa un usuario con sudo."
  exit 1
fi

# ---------------------------------------------------------------------------
# Sistema
# ---------------------------------------------------------------------------
log "Actualizando el sistema"
sudo pacman -Syu --noconfirm

# ---------------------------------------------------------------------------
# Multilib (necesario para Steam)
# ---------------------------------------------------------------------------
if ! grep -qE '^\[multilib\]' /etc/pacman.conf; then
  log "Habilitando repositorio [multilib]"
  sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/{s/^#//}' /etc/pacman.conf
  sudo pacman -Sy --noconfirm
fi

# ---------------------------------------------------------------------------
# Básicos (+ base-devel para AUR)
# ---------------------------------------------------------------------------
log "Instalando paquetes oficiales"
sudo pacman -S --needed --noconfirm \
  base-devel \
  git curl wget \
  vim \
  jre-openjdk \
  p7zip unrar \
  gnome-tweaks \
  gparted \
  wireshark-qt nmap \
  calibre \
  zsh \
  python python-pip python-virtualenv \
  discord \
  telegram-desktop \
  vlc \
  audacity \
  kdenlive \
  steam \
  flatpak

# ---------------------------------------------------------------------------
# yay (AUR helper)
# ---------------------------------------------------------------------------
if ! command -v yay >/dev/null 2>&1; then
  log "Instalando yay"
  TMP_DIR="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "${TMP_DIR}/yay"
  (cd "${TMP_DIR}/yay" && makepkg -si --noconfirm)
  rm -rf "${TMP_DIR}"
else
  log "yay ya está instalado"
fi

# ---------------------------------------------------------------------------
# AUR
# ---------------------------------------------------------------------------
log "Instalando paquetes AUR"
yay -S --needed --noconfirm \
  google-chrome \
  dropbox \
  postman-bin \
  spotify \
  sublime-text-4 \
  opera \
  visual-studio-code-bin \
  localsend-bin

# ---------------------------------------------------------------------------
# Batería (portátiles)
# ---------------------------------------------------------------------------
CHASSIS="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)"
if [[ "${CHASSIS}" =~ ^(8|9|10|11|14)$ ]]; then
  log "Portátil detectado: instalando TLP"
  sudo pacman -S --needed --noconfirm tlp tlp-rdw
  sudo systemctl enable --now tlp
else
  log "No parece un portátil; se omite TLP"
fi

# ---------------------------------------------------------------------------
# Python (venv de usuario)
# ---------------------------------------------------------------------------
log "Creando venv e instalando requirements.txt"
VENV_DIR="${HOME}/.venvs/default"
python -m venv "${VENV_DIR}"
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
pip install --upgrade pip
if [[ -f "${SCRIPT_DIR}/requirements.txt" ]]; then
  pip install -r "${SCRIPT_DIR}/requirements.txt"
fi
deactivate
printf '\nAñade al PATH si quieres: source %s/bin/activate\n' "${VENV_DIR}"

# ---------------------------------------------------------------------------
# Flatpak (Flathub)
# ---------------------------------------------------------------------------
log "Configurando Flathub"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# ---------------------------------------------------------------------------
# Oh My Zsh
# ---------------------------------------------------------------------------
log "Instalando Oh My Zsh"
if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
  chsh -s "$(command -v zsh)" || warn "No se pudo cambiar el shell; ejecuta: chsh -s \$(which zsh)"
else
  log "Oh My Zsh ya está instalado"
fi

log "Listo."

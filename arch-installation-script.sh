#!/usr/bin/env bash
# Post-install setup for Arch Linux (y derivados basados en pacman).
# Idempotente: se puede reejecutar sin romper lo ya instalado.
set -euo pipefail

log()  { printf '\n==> %s\n' "$*"; }
skip() { printf '  skip: %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

FLATPAK_APPS=(
  com.discordapp.Discord
  com.google.Chrome
  com.spotify.Client
  org.telegram.desktop
  org.videolan.VLC
  org.audacityteam.Audacity
  org.kde.kdenlive
  com.opera.Opera
  com.getpostman.Postman
  com.sublimehq.SublimeText
  com.visualstudio.code
  org.localsend.localsend_app
)

pacman_installed() { pacman -Qi "$1" &>/dev/null; }
flatpak_installed() { flatpak info "$1" &>/dev/null; }

ensure_flathub() {
  if flatpak remotes --columns=name 2>/dev/null | grep -qx flathub; then
    skip "Flathub ya configurado"
  else
    log "Configurando Flathub"
    flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo
  fi
}

ensure_flatpak_apps() {
  local app
  for app in "${FLATPAK_APPS[@]}"; do
    if flatpak_installed "${app}"; then
      skip "${app}"
    else
      log "Instalando Flatpak ${app}"
      flatpak install -y flathub "${app}"
    fi
  done
}

ensure_oh_my_zsh() {
  if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    log "Instalando Oh My Zsh"
    RUNZSH=no CHSH=no \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      "" --unattended
  else
    skip "Oh My Zsh ya instalado"
  fi

  local zsh_path current_shell
  zsh_path="$(command -v zsh)"
  current_shell="$(getent passwd "${USER}" | cut -d: -f7)"
  if [[ "${current_shell}" == "${zsh_path}" ]]; then
    skip "shell ya es zsh"
  else
    chsh -s "${zsh_path}" || warn "No se pudo cambiar el shell; ejecuta: chsh -s \$(which zsh)"
  fi
}

if [[ "${EUID}" -eq 0 ]]; then
  warn "No ejecutes este script como root. Usa un usuario con sudo."
  exit 1
fi

# Mantener sudo activo durante toda la instalación
sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "${SUDO_KEEPALIVE_PID}" 2>/dev/null || true' EXIT

# ---------------------------------------------------------------------------
# Sistema
# ---------------------------------------------------------------------------
log "Actualizando el sistema"
sudo pacman -Syu --noconfirm

# ---------------------------------------------------------------------------
# Multilib (necesario para Steam)
# ---------------------------------------------------------------------------
if grep -qE '^\[multilib\]' /etc/pacman.conf; then
  skip "[multilib] ya habilitado"
else
  log "Habilitando repositorio [multilib]"
  sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/{s/^#//}' /etc/pacman.conf
  sudo pacman -Sy --noconfirm
fi

# ---------------------------------------------------------------------------
# Básicos (pacman --needed es idempotente)
# ---------------------------------------------------------------------------
log "Instalando paquetes oficiales"
sudo pacman -S --needed --noconfirm \
  base-devel \
  git curl wget \
  vim \
  p7zip unrar \
  gnome-tweaks \
  gparted \
  zsh \
  python python-pip python-virtualenv \
  steam \
  flatpak

# ---------------------------------------------------------------------------
# Codecs / firmware
# ---------------------------------------------------------------------------
log "Instalando codecs multimedia"
sudo pacman -S --needed --noconfirm \
  ffmpeg \
  gst-libav \
  gst-plugins-base \
  gst-plugins-good \
  gst-plugins-bad \
  gst-plugins-ugly \
  libdvdcss \
  linux-firmware

# ---------------------------------------------------------------------------
# yay (AUR helper)
# ---------------------------------------------------------------------------
if command -v yay >/dev/null 2>&1; then
  skip "yay ya instalado"
else
  log "Instalando yay"
  TMP_DIR="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "${TMP_DIR}/yay"
  (cd "${TMP_DIR}/yay" && makepkg -si --noconfirm)
  rm -rf "${TMP_DIR}"
fi

if pacman_installed dropbox; then
  skip "Dropbox ya instalado"
else
  log "Instalando Dropbox (AUR)"
  yay -S --needed --noconfirm dropbox
fi

# ---------------------------------------------------------------------------
# Flatpak / Flathub
# ---------------------------------------------------------------------------
ensure_flathub
log "Comprobando aplicaciones Flatpak"
ensure_flatpak_apps

# ---------------------------------------------------------------------------
# Batería (portátiles)
# ---------------------------------------------------------------------------
CHASSIS="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)"
if [[ "${CHASSIS}" =~ ^(8|9|10|11|14)$ ]]; then
  if systemctl is-enabled tlp &>/dev/null; then
    skip "TLP ya activo"
  else
    log "Portátil detectado: instalando TLP"
    sudo pacman -S --needed --noconfirm tlp tlp-rdw
    sudo systemctl enable --now tlp
  fi
else
  skip "no es portátil; se omite TLP"
fi

# ---------------------------------------------------------------------------
# Oh My Zsh
# ---------------------------------------------------------------------------
ensure_oh_my_zsh

log "Listo."

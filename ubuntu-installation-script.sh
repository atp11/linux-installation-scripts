#!/usr/bin/env bash
# Post-install setup for Ubuntu (22.04 / 24.04 / 26.04 LTS and derivatives).
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

apt_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; }
flatpak_installed() { flatpak info "$1" &>/dev/null; }

ensure_flathub() {
  if flatpak remotes --columns=name 2>/dev/null | grep -qx flathub; then
    skip "Flathub ya configurado"
  else
    log "Configurando Flathub"
    sudo flatpak remote-add --if-not-exists flathub \
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
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean

# ---------------------------------------------------------------------------
# Básicos (apt install es idempotente)
# ---------------------------------------------------------------------------
log "Instalando paquetes básicos"
sudo apt install -y \
  build-essential \
  default-jre \
  synaptic \
  p7zip-full p7zip-rar unrar \
  git \
  gnome-tweaks \
  curl wget \
  ca-certificates \
  gnupg \
  apt-transport-https \
  software-properties-common \
  vim \
  gparted \
  wireshark \
  nmap \
  calibre \
  zsh \
  python3-pip \
  python3-venv \
  python3-gpg \
  libappindicator3-1 \
  flatpak \
  steam-installer

# ---------------------------------------------------------------------------
# Flatpak / Flathub
# ---------------------------------------------------------------------------
ensure_flathub
log "Comprobando aplicaciones Flatpak"
ensure_flatpak_apps

# ---------------------------------------------------------------------------
# Dropbox
# ---------------------------------------------------------------------------
if apt_installed dropbox || command -v dropbox >/dev/null 2>&1; then
  skip "Dropbox ya instalado"
else
  log "Instalando Dropbox"
  TMP_DIR="$(mktemp -d)"
  DROPBOX_DEB="$(
    curl -fsSL https://linux.dropbox.com/packages/ubuntu/ \
      | grep -oE 'dropbox_[0-9]{4}\.[0-9]{2}\.[0-9]{2}_amd64\.deb' \
      | sort -V | tail -1
  )"
  if [[ -n "${DROPBOX_DEB}" ]]; then
    wget -q -O "${TMP_DIR}/dropbox.deb" \
      "https://linux.dropbox.com/packages/ubuntu/${DROPBOX_DEB}"
    sudo apt install -y "${TMP_DIR}/dropbox.deb"
  else
    warn "No se pudo resolver el paquete Dropbox; instálalo manualmente desde dropbox.com"
  fi
  rm -rf "${TMP_DIR}"
fi

# ---------------------------------------------------------------------------
# Batería (portátiles)
# ---------------------------------------------------------------------------
CHASSIS="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)"
if [[ "${CHASSIS}" =~ ^(8|9|10|11|14)$ ]]; then
  if systemctl is-enabled tlp &>/dev/null; then
    skip "TLP ya activo"
  else
    log "Portátil detectado: instalando TLP"
    sudo apt install -y tlp tlp-rdw
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

#!/usr/bin/env bash
# Post-install setup for Ubuntu (22.04 / 24.04 / 26.04 LTS and derivatives).
set -euo pipefail

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
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean

# ---------------------------------------------------------------------------
# Básicos
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
# Flatpak / Flathub (canal unificado de apps de escritorio)
# ---------------------------------------------------------------------------
log "Configurando Flathub"
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

log "Instalando aplicaciones (Flatpak)"
flatpak install -y flathub \
  com.discordapp.Discord \
  com.google.Chrome \
  com.spotify.Client \
  org.telegram.desktop \
  org.videolan.VLC \
  org.audacityteam.Audacity \
  org.kde.kdenlive \
  com.opera.Opera \
  com.getpostman.Postman \
  com.sublimehq.SublimeText \
  com.visualstudio.code \
  org.localsend.localsend_app

# ---------------------------------------------------------------------------
# Dropbox
# ---------------------------------------------------------------------------
log "Instalando Dropbox"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
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

# ---------------------------------------------------------------------------
# Batería (portátiles)
# ---------------------------------------------------------------------------
CHASSIS="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)"
if [[ "${CHASSIS}" =~ ^(8|9|10|11|14)$ ]]; then
  log "Portátil detectado: instalando TLP"
  sudo apt install -y tlp tlp-rdw
  sudo systemctl enable --now tlp
else
  log "No parece un portátil; se omite TLP"
fi

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

#!/usr/bin/env bash
# Post-install setup for Fedora Workstation.
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
sudo dnf -y upgrade
sudo dnf -y autoremove
sudo dnf -y clean all

# ---------------------------------------------------------------------------
# RPM Fusion (codecs / extras / Steam)
# ---------------------------------------------------------------------------
log "Habilitando RPM Fusion"
FEDORA_VERSION="$(rpm -E %fedora)"
sudo dnf -y install \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

# ---------------------------------------------------------------------------
# Básicos
# ---------------------------------------------------------------------------
log "Instalando paquetes básicos"
sudo dnf -y install \
  curl wget \
  git \
  java-latest-openjdk \
  unrar p7zip p7zip-plugins \
  vim \
  gparted \
  wireshark \
  nmap \
  calibre \
  zsh \
  python3-pip \
  python3-virtualenv \
  gnome-tweaks \
  flatpak \
  libappindicator-gtk3 \
  steam

# ---------------------------------------------------------------------------
# Flatpak / Flathub (preferido en Fedora frente a snap)
# ---------------------------------------------------------------------------
log "Configurando Flathub"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

log "Instalando aplicaciones (Flatpak)"
flatpak install -y flathub \
  com.discordapp.Discord \
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
log "Instalando Dropbox (nautilus-dropbox)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
DROPBOX_RPM="$(
  curl -fsSL https://linux.dropbox.com/packages/fedora/ \
    | grep -oE "nautilus-dropbox-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9]+\.fc[0-9]+\.x86_64\.rpm" \
    | sort -V | tail -1
)"
if [[ -n "${DROPBOX_RPM}" ]]; then
  wget -q -O "${TMP_DIR}/dropbox.rpm" \
    "https://linux.dropbox.com/packages/fedora/${DROPBOX_RPM}"
  sudo dnf -y install "${TMP_DIR}/dropbox.rpm"
else
  warn "No se pudo resolver el RPM de Dropbox; instálalo manualmente desde dropbox.com"
fi

# ---------------------------------------------------------------------------
# Batería (portátiles)
# ---------------------------------------------------------------------------
CHASSIS="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)"
if [[ "${CHASSIS}" =~ ^(8|9|10|11|14)$ ]]; then
  log "Portátil detectado: instalando TLP"
  sudo dnf -y install tlp tlp-rdw
  sudo systemctl enable --now tlp
else
  log "No parece un portátil; se omite TLP"
fi

# ---------------------------------------------------------------------------
# Google Chrome
# ---------------------------------------------------------------------------
log "Instalando Google Chrome"
wget -q -O "${TMP_DIR}/chrome.rpm" \
  https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
sudo dnf -y install "${TMP_DIR}/chrome.rpm"

# ---------------------------------------------------------------------------
# Python (venv de usuario)
# ---------------------------------------------------------------------------
log "Creando venv e instalando requirements.txt"
VENV_DIR="${HOME}/.venvs/default"
python3 -m venv "${VENV_DIR}"
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
pip install --upgrade pip
if [[ -f "${SCRIPT_DIR}/requirements.txt" ]]; then
  pip install -r "${SCRIPT_DIR}/requirements.txt"
fi
deactivate
printf '\nAñade al PATH si quieres: source %s/bin/activate\n' "${VENV_DIR}"

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

#!/usr/bin/env bash
# Post-install setup for Fedora Workstation.
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

rpm_installed() { rpm -q "$1" &>/dev/null; }
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
FEDORA_VERSION="$(rpm -E %fedora)"
if rpm_installed rpmfusion-free-release && rpm_installed rpmfusion-nonfree-release; then
  skip "RPM Fusion ya habilitado"
else
  log "Habilitando RPM Fusion"
  sudo dnf -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"
fi

# ---------------------------------------------------------------------------
# Básicos (dnf install es idempotente)
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
# Flatpak / Flathub
# ---------------------------------------------------------------------------
ensure_flathub
log "Comprobando aplicaciones Flatpak"
ensure_flatpak_apps

# ---------------------------------------------------------------------------
# Dropbox
# ---------------------------------------------------------------------------
if rpm_installed nautilus-dropbox || command -v dropbox >/dev/null 2>&1; then
  skip "Dropbox ya instalado"
else
  log "Instalando Dropbox (nautilus-dropbox)"
  TMP_DIR="$(mktemp -d)"
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
    sudo dnf -y install tlp tlp-rdw
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

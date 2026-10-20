#!/usr/bin/env bash
# Post-install setup for Ubuntu (22.04 / 24.04 / 26.04 LTS and derivatives).
# Idempotente: se puede reejecutar sin romper lo ya instalado.
set -euo pipefail

# Dotfiles: exporta DOTFILES_REPO o edita el valor por defecto.
# Ejemplo: DOTFILES_REPO="https://github.com/usuario/dotfiles.git"
DOTFILES_REPO="${DOTFILES_REPO:-}"
DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"

# Dropbox: INSTALL_DROPBOX=1 para instalar (omitido por defecto).
INSTALL_DROPBOX="${INSTALL_DROPBOX:-0}"

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

ensure_oh_my_zsh_plugin() {
  local name="$1" repo="$2"
  local dest="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/${name}"
  if [[ -d "${dest}" ]]; then
    skip "plugin ${name} ya instalado"
  else
    log "Instalando plugin ${name}"
    git clone --depth=1 "${repo}" "${dest}"
  fi
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

  ensure_oh_my_zsh_plugin zsh-autosuggestions \
    https://github.com/zsh-users/zsh-autosuggestions.git
  ensure_oh_my_zsh_plugin zsh-syntax-highlighting \
    https://github.com/zsh-users/zsh-syntax-highlighting.git

  local zshrc="${HOME}/.zshrc"
  if [[ -f "${zshrc}" ]]; then
    if grep -qE '^\s*plugins=\(.*zsh-autosuggestions.*zsh-syntax-highlighting' "${zshrc}"; then
      skip "plugins ya habilitados en .zshrc"
    else
      log "Habilitando plugins en .zshrc"
      # syntax-highlighting debe ir al final de la lista
      sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "${zshrc}"
    fi
  else
    warn "No existe ~/.zshrc; habilita los plugins manualmente"
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

ensure_dotfiles() {
  if [[ -z "${DOTFILES_REPO}" ]]; then
    skip "DOTFILES_REPO vacío; se omiten dotfiles"
    return 0
  fi

  if [[ -d "${DOTFILES_DIR}/.git" ]]; then
    skip "dotfiles ya clonados en ${DOTFILES_DIR}"
  else
    log "Clonando dotfiles → ${DOTFILES_DIR}"
    git clone "${DOTFILES_REPO}" "${DOTFILES_DIR}"
  fi

  local installer=""
  for candidate in install.sh bootstrap.sh setup.sh; do
    if [[ -x "${DOTFILES_DIR}/${candidate}" ]]; then
      installer="${DOTFILES_DIR}/${candidate}"
      break
    elif [[ -f "${DOTFILES_DIR}/${candidate}" ]]; then
      installer="${DOTFILES_DIR}/${candidate}"
      break
    fi
  done

  if [[ -n "${installer}" ]]; then
    log "Ejecutando $(basename "${installer}")"
    # shellcheck disable=SC1090
    bash "${installer}"
  else
    warn "No hay install.sh/bootstrap.sh/setup.sh en ${DOTFILES_DIR}; aplica los enlaces a mano"
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
  zsh \
  python3-pip \
  python3-venv \
  python3-gpg \
  libappindicator3-1 \
  flatpak \
  steam-installer

# ---------------------------------------------------------------------------
# Codecs / firmware
# ---------------------------------------------------------------------------
log "Instalando codecs y extras multimedia"
# Acepta la EULA de fuentes Microsoft sin prompt interactivo
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true \
  | sudo debconf-set-selections
sudo apt install -y \
  ubuntu-restricted-extras \
  ubuntu-restricted-addons \
  libavcodec-extra \
  linux-firmware

# ---------------------------------------------------------------------------
# Flatpak / Flathub
# ---------------------------------------------------------------------------
ensure_flathub
log "Comprobando aplicaciones Flatpak"
ensure_flatpak_apps

# ---------------------------------------------------------------------------
# Dropbox (opcional)
# ---------------------------------------------------------------------------
if [[ "${INSTALL_DROPBOX}" != "1" ]]; then
  skip "Dropbox omitido (INSTALL_DROPBOX=1 para instalar)"
elif apt_installed dropbox || command -v dropbox >/dev/null 2>&1; then
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

# ---------------------------------------------------------------------------
# Dotfiles
# ---------------------------------------------------------------------------
ensure_dotfiles

log "Listo."

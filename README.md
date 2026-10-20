# linux-installation-scripts

Scripts de post-instalación para dejar un Linux nuevo a tu gusto (paquetes base, apps de escritorio, Python y Oh My Zsh).

## Distros

| Distro | Instalación | Actualización |
|--------|-------------|---------------|
| Ubuntu | `ubuntu-installation-script.sh` | `ubuntu-update.sh` |
| Arch   | `arch-installation-script.sh`   | `arch-update.sh` |
| Fedora | `fedora-installation-script.sh` | `fedora-update.sh` |

## Uso

```bash
chmod +x *.sh
./ubuntu-installation-script.sh   # o arch- / fedora-
```

Ejecuta los scripts con un usuario que tenga `sudo`, **no como root**.

## Qué instalan (resumen)

- Herramientas: git, curl, vim, gparted, wireshark, nmap, calibre, JRE, zsh + Oh My Zsh
- Chrome, Discord, Telegram, Spotify, VLC, Audacity, Kdenlive, Opera, Postman, Sublime Text
- Steam, Visual Studio Code, LocalSend
- Dropbox (paquete oficial o AUR)
- TLP solo si se detecta un portátil
- Python: venv en `~/.venvs/default` con `requirements.txt` (evita romper el Python del sistema / PEP 668)

## Notas por distro

- **Ubuntu**: apps de escritorio vía Snap; Steam con `steam-installer`.
- **Arch**: `pacman` + `yay`; habilita `[multilib]` para Steam.
- **Fedora**: Flatpak/Flathub; RPM Fusion (necesario para Steam).

## Python

```bash
source ~/.venvs/default/bin/activate
```

Los scripts de update también intentan actualizar los paquetes del venv si existe.

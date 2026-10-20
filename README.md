# linux-installation-scripts

Scripts de post-instalación para dejar un Linux nuevo a tu gusto (paquetes base, Docker, apps de escritorio, Python y Oh My Zsh).

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

Tras la instalación, cierra sesión (o reinicia) para que el grupo `docker` aplique.

## Qué instalan (resumen)

- Herramientas: git, curl, vim, gparted, wireshark, nmap, calibre, JRE, zsh + Oh My Zsh
- Docker Engine oficial (+ compose/buildx) y usuario en el grupo `docker`
- Chrome, Discord, Telegram, Spotify, VLC, Audacity, Kdenlive, Opera, Postman, Sublime Text
- Dropbox (paquete oficial o AUR)
- Teams: `teams-for-linux` (wrapper no oficial; Microsoft ya no publica cliente nativo para Linux — la alternativa oficial es la PWA)
- TLP solo si se detecta un portátil
- Python: venv en `~/.venvs/default` con `requirements.txt` (evita romper el Python del sistema / PEP 668)

## Notas por distro

- **Ubuntu**: apps de escritorio vía Snap; Docker con keyrings modernos (sin `apt-key`).
- **Arch**: reescritos con `pacman` + `yay` (antes estaban copiados del script de Ubuntu).
- **Fedora**: Flatpak/Flathub en lugar de Snap; RPM Fusion; Docker vía repo oficial.

## Python

```bash
source ~/.venvs/default/bin/activate
```

Los scripts de update también intentan actualizar los paquetes del venv si existe.

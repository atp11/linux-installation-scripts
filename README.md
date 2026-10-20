# linux-installation-scripts

Scripts de post-instalación para dejar un Linux nuevo a tu gusto (paquetes base, apps de escritorio vía Flatpak y Oh My Zsh).

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

Los scripts de instalación son **idempotentes**: puedes reejecutarlos tras un fallo a mitad; lo ya instalado se omite (`skip: …`).

Piden `sudo` una sola vez al inicio y lo mantienen activo durante la instalación.

## Qué instalan (resumen)

- Herramientas: git, curl, vim, gparted, zsh + Oh My Zsh (plugins: autosuggestions, syntax-highlighting)
- Python: `pip` + `venv` (sin librerías globales; crea un venv por proyecto cuando lo necesites)
- Chrome, Discord, Telegram, Spotify, VLC, Audacity, Kdenlive, Opera, Postman, Sublime Text
- Steam, Visual Studio Code, LocalSend
- Dropbox (paquete oficial o AUR)
- Codecs multimedia / firmware (Ubuntu restricted extras, GStreamer/ffmpeg, etc.)
- TLP solo si se detecta un portátil

## Notas por distro

- **Apps de escritorio**: Flatpak/Flathub en las tres (Discord, Chrome, Spotify, Telegram, VLC, Audacity, Kdenlive, Opera, Postman, Sublime Text, VS Code, LocalSend).
- **Nativo**: herramientas de sistema, Steam, Dropbox, TLP, Oh My Zsh.
- **Ubuntu**: Steam con `steam-installer`.
- **Arch**: `pacman` + `yay` (Dropbox); habilita `[multilib]` para Steam.
- **Fedora**: RPM Fusion (necesario para Steam).

Los scripts de update refrescan Flatpak (`flatpak update`).

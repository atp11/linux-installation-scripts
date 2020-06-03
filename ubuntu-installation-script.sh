#!/bin/bash

# Update system
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean

# Basics
sudo apt install build-essential -y
sudo apt install default-jre -y
sudo apt install synaptic -y
sudo apt install p7zip-full p7zip-rar unrar -y
sudo apt install git -y
sudo apt install gnome-tweak-tool -y
sudo apt install curl -y
sudo apt install wget -y
sudo apt install apt-transport-https -y
sudo apt install ca-certificates -y
sudo apt install gnupg-agent -y
sudo apt install software-properties-common -y

# Communication
wget https://github.com/meetfranz/franz/releases/download/v5.5.0/franz_5.5.0_amd64.deb
wget -O discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
wget https://packages.microsoft.com/repos/ms-teams/pool/main/t/teams/teams_1.3.00.5153_amd64.deb
sudo dpkg -i franz*.deb
sudo dpkg -i discord.deb
sudo dpkg -i teams*.deb
rm *.deb

# Tools
sudo apt install vim -y
sudo apt install gparted -y
sudo apt install wireshark -y
sudo apt install nmap -y

# Docker
sudo apt-get remove docker docker-engine docker.io containerd runc
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# Dropbox
sudo echo "deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu bionic main" > /etc/apt/sources.list.d/dropbox.list
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
sudo apt update
sudo apt install python3-gpg dropbox

# Battery (only laptop)
sudo apt install tlp tlp-rdw -y
sudo tlp start

# Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo gdebi google-chrome-stable_current_amd64.deb

# Python 3 (pip and packages)
sudo apt install python3-pip -y
python3 -m pip install -r requirements.txt

# Calibre
sudo apt install calibre -y

# Snapshots (snapcraft.io)
sudo snap install vlc
sudo snap install audacity
sudo snap install kdenlive
sudo snap install opera
sudo snap install postman
sudo snap install spotify
sudo snap install sublime-text
sudo snap install telegram-desktop

# Oh My Zsh
sudo apt install zsh -y
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

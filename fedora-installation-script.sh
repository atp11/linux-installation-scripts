#!/bin/bash

# Update system
sudo dnf -y upgrade
sudo dnf -y autoremove
sudo dnf -y clean all

# Basics
sudo dnf -y install curl
sudo dnf -y install wget
sudo dnf install git-all
sudo dnf -y install unrar p7zip p7zip-plugins
sudo dnf -y install java

# Communication
wget https://packages.microsoft.com/yumrepos/ms-teams/teams-1.2.00.32451-1.x86_64.rpm
sudo dnf localinstall teams-1.2.00.32451-1.x86_64.rpm
rm *.rpm

# Tools
sudo dnf -y install vim
su -c "yum install gparted"
sudo dnf -y install wireshark-qt
sudo yum install nmap

#TODO AQUI

# Docker
sudo apt-get remove docker docker-engine docker.io containerd runc
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io -y

# Dropbox
sudo echo "deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu bionic main" > /etc/apt/sources.list.d/dropbox.list
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
sudo apt update
sudo apt install python3-gpg dropbox -y

# Battery (only laptop)
sudo apt install tlp tlp-rdw -y
sudo tlp start

# Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# Python 3 (pip and packages)
sudo apt install python3-pip -y
python3 -m pip install -r requirements.txt

# Calibre
sudo apt install calibre -y

# Snapshots (snapcraft.io)
sudo dnf install snapd
sudo ln -s /var/lib/snapd/snap /snap

sudo snap install vlc
sudo snap install audacity
sudo snap install kdenlive
sudo snap install opera
sudo snap install postman
sudo snap install spotify
sudo snap install sublime-text
sudo snap install telegram-desktop
sudo snap install discord

# Oh My Zsh
sudo apt install zsh -y
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

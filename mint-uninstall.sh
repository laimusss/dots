#!/bin/bash
set -e

# Резервная копия пакетов
dpkg --get-selections > $HOME/packages-list-$(date +%Y%m%d-%H%M%S).txt

# Удаление пакетов
sudo apt purge -y celluloid hypnotix rhythmbox rhythmbox-plugins drawing pix simple-scan \
  firefox firefox-locale-* thunderbird thunderbird-locale-* transmission-gtk transmission-cli 
transmission-common \
  thingy sticky libreoffice-core libreoffice-common onboard warpinator

sudo apt autoremove -y && sudo apt autoclean

# Установка темы и иконок
mkdir -p $HOME/.themes $HOME/.icons

git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git $HOME/.themes/ -q
bash $HOME/.themes/Orchis-theme/install.sh -c dark -s compact --tweaks dracula --round 3 -q
rm -rf $HOME/.themes/Orchis-theme

git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git $HOME/.icons/ -q
bash $HOME/.icons/Tela-circle-icon-theme/install.sh dracula -c -q
rm -rf $HOME/.icons/Tela-circle-icon-theme

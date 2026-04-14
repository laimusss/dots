#!/bin/bash
set -e

# Удаление пакетов
sudo apt purge -y celluloid hypnotix rhythmbox* drawing pix simple-scan firefox* thunderbird* transmission* thingy sticky libreoffice* onboard warpinator

sudo apt autoremove -y && sudo apt autoclean

# Установка темы и иконок
mkdir -p ~/.themes ~/.icons

git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git ~/.themes/ -q
bash ~/.themes/Orchis-theme/install.sh -c dark -s compact --tweaks dracula --round 3 -q
rm -rf ~/.themes/Orchis-theme

git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git ~/.icons/ -q
bash ~/.icons/Tela-circle-icon-theme/install.sh dracula -c -q
rm -rf ~/.icons/Tela-circle-icon-theme



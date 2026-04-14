#!/bin/bash
set -e

# Определяем HOME (на случай если запущено через sudo)
export HOME="$(eval echo ~$(whoami))"

# Удаление пакетов
sudo apt purge -y celluloid hypnotix rhythmbox* drawing pix simple-scan firefox* thunderbird* transmission* thingy sticky libreoffice* onboard warpinator

sudo apt autoremove -y && sudo apt autoclean

# Установка темы и иконок
mkdir -p "${HOME}/.themes"
mkdir -p "${HOME}/.icons"

# Тема
if [ -d "${HOME}/.themes/Orchis-theme" ]; then
    rm -rf "${HOME}/.themes/Orchis-theme"
fi
git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git 
"${HOME}/.themes/Orchis-theme" -q
bash "${HOME}/.themes/Orchis-theme/install.sh" -c dark -s compact --tweaks dracula --round 3 
-q
rm -rf "${HOME}/.themes/Orchis-theme"

# Иконки
if [ -d "${HOME}/.icons/Tela-circle-icon-theme" ]; then
    rm -rf "${HOME}/.icons/Tela-circle-icon-theme"
fi
git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git 
"${HOME}/.icons/Tela-circle-icon-theme" -q
bash "${HOME}/.icons/Tela-circle-icon-theme/install.sh" dracula -c -q
rm -rf "${HOME}/.icons/Tela-circle-icon-theme"

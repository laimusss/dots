#!/bin/bash
set -e

# Определяем HOME (на случай если запущено через sudo)
export HOME="$(eval echo ~$(whoami))"

# Удаление пакетов
sudo apt purge -y celluloid hypnotix rhythmbox* drawing pix simple-scan firefox* thunderbird* transmission* thingy sticky libreoffice* onboard warpinator && sudo apt install -y sassc

sudo apt autoremove -y && sudo apt autoclean

echo ""
echo "🎨 Установка тем..."

USER_HOME="/home/$ORIGINAL_USER"
[ "$ORIGINAL_USER" = "root" ] && USER_HOME="/root"

mkdir -p "$USER_HOME/.themes"
cd "$USER_HOME/.themes" || exit 1
git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git
cd Orchis-theme/
bash ./install.sh -c dark -s compact --tweaks dracula --round 1

cd "$USER_HOME" || exit 1
mkdir -p "$USER_HOME/.icons"
cd "$USER_HOME/.icons" || exit 1
git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git
cd Tela-circle-icon-theme/
bash ./install.sh dracula -c

cd "$USER_HOME" || exit 1

#!/bin/bash

# Скрипт для удаления ненужных пакетов
# Создаем резервную копию списка установленных пакетов
echo "Создание резервной копии списка пакетов..."
dpkg --get-selections > ~/packages-list-$(date +%Y%m%d-%H%M%S).txt

Альтернативный вариант с более точным указанием пакетов:
sudo apt purge -y \
     celluloid \
     hypnotix \
     rhythmbox rhythmbox-plugins \
     drawing \
     pix \
     simple-scan \
     firefox firefox-locale-* \
     thunderbird thunderbird-locale-* \
     transmission-gtk transmission-cli transmission-common \
     thingy \
     sticky \
     libreoffice-core libreoffice-common \
     onboard \
     warpinator

echo "Удаление зависимостей, которые больше не нужны..."
sudo apt autoremove -y

echo "Очистка кэша пакетов..."
sudo apt autoclean

echo "Очистка завершена!"

# Themes
# Путь к директории
themes_dir="/home/$username/.themes"

# Проверяем, существует ли директория, и если нет — создаём её
if [ ! -d "$themes_dir" ]; then
    echo "Директория $themes_dir не найдена. Создаём..."
    mkdir -p "$themes_dir"
    echo "Директория $themes_dir успешно создана."
else
    echo "Директория $themes_dir уже существует."
fi
cd /home/$username/.themes && git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git && cd Orchis-theme/ && bash ./install.sh -c dark -s compact --tweaks dracula --round 3 && cd

# Icons
# Путь к директории
icons_dir="/home/$username/.icons"

# Проверяем, существует ли директория, и если нет — создаём её
if [ ! -d "$icons_dir" ]; then
    echo "Директория $icons_dir не найдена. Создаём..."
    mkdir -p "$themes_dir"
    echo "Директория $icons_dir успешно создана."
else
    echo "Директория $icons_dir уже существует."
fi
cd /home/$username/.icons && git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git && cd Tela-circle-icon-theme/ && bash ./install.sh dracula -c && cd

echo "Themes & Icons Installed!"

echo ""
read -p ">>> Установить Ulauncher? (y/n) " choice
echo ""
if [ "$choice" == "y" ]; then
sudo add-apt-repository universe -y && sudo add-apt-repository ppa:agornostal/ulauncher -y && sudo apt update && sudo apt install ulauncher -y && git clone https://github.com/sotsugov/ulauncher-eigen/ \
  ~/.config/ulauncher/user-themes/eigen-dark
echo ""
echo "| Ulauncher установлен"
else
echo "| Установка пропущена"
fi

echo ""
read -p ">>> Установить Brave Browser? (y/n) " choice
echo ""
if [ "$choice" == "y" ]; then
curl -fsS https://dl.brave.com/install.sh | sh
echo ""
echo "| Brave Browser установлен"
else
echo "| Установка пропущена"
fi



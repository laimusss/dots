#!/bin/bash

# Установка зависимостей
sudo apt update
sudo apt install -y git build-essential libpam0g-dev libxcb1-dev libxcb-keysyms1-dev libxcb-util-dev

# Клонирование репозитория ly
git clone --recursive https://github.com/nullgemm/ly.git
cd ly

# Сборка
make

# Установка
sudo make install

# Отключение текущего дисплейного менеджера (например, gdm3, lightdm и т.д.)
sudo systemctl disable display-manager
sudo systemctl enable ly.service

# Перезагрузка для применения изменений
echo "Установка завершена. Перезагрузите систему для запуска ly."

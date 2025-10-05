#!/bin/bash

# Убедитесь, что вы запускаете скрипт с правами суперпользователя
if [[ "$EUID" -ne 0 ]]; then
 echo "Пожалуйста, запустите скрипт от имени суперпользователя (sudo)."
 exit 1
fi

# Установка Nala, если он не установлен
if ! command -v nala &> /dev/null; then
 echo "Nala не установлен. Установка Nala..."
 apt update && apt install -y nala
else
 echo "Nala уже установлен."
fi

# Запрос имени пользователя для автоматического входа
read -p "Введите имя пользователя для автоматического входа: " username

# Создание директории и конфигурационного файла для автологина
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
Type=simple
ExecStart=
ExecStart=-/sbin/agetty --autologin $username --noclear %I 38400 linux
EOF

# Настройка автоматического запуска X-сессии в ~/.profile
profile_file="/home/$username/.profile"
{
  echo "# Запуск X-сессии автоматически, если она еще не запущена"
  echo "if [[ -z \"\$DISPLAY\" ]] && [[ \$(tty) = /dev/tty1 ]]; then"
  echo " exec startx"
  echo "fi"
} >> "$profile_file"

# Создание файла ~/.xinitrc для запуска Budgie
xinitrc_file="/home/$username/.xinitrc"
echo "exec budgie-desktop" > "$xinitrc_file"

# Установка Budgie-desktop, если он не установлен
if ! dpkg -l | grep -q budgie-desktop; then
 echo "Установка Budgie-desktop..."
 nala install -y xserver-xorg-core xinit budgie-desktop alacritty
else
 echo "Budgie-desktop уже установлен."
fi

# Установка файлового менеджера и утилит
echo "Установка файлового менеджера и утилит..."
nala install -y pcmanfm engrampa

# Установка мультимедиа утилит
echo "Установка мультимедиа утилит..."
nala install -y pulseaudio pulseaudio-utils pavucontrol playerctl moc mpv

# Установка текстовых редакторов
echo "Установка текстовых редакторов..."
nala install -y micro

# Дополнительные скрипты
source ./install_wifi-macbookpro.sh
source ./install-onlyoffice-debian.sh

# Очистка системы
sudo nala -y autopurge

# Завершение
echo "Настройка завершена. Пожалуйста, перезагрузите систему."

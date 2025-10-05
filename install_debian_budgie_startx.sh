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

# Установка пакета budgie-desktop, если он не установлен
if ! dpkg -l | grep -q budgie-desktop; then
 echo "Установка пакета budgie-desktop..."
 nala install -y xserver-xorg-core xinit budgie-desktop alacritty
else
 echo "Пакет budgie-desktop уже установлен."
fi

# Завершение
echo "Настройка завершена. Пожалуйста, перезагрузите систему."

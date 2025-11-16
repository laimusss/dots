#!/bin/bash

# Скрипт установки ly - легковесного менеджера входа для Debian 13

set -e  # Остановить выполнение при ошибке

echo "=== Установка ly менеджера входа ==="

# Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка необходимых зависимостей
echo "Установка зависимостей..."
sudo apt install -y \
    build-essential \
    libpam0g-dev \
    libxcb-xkb-dev \
    libx11-dev \
    libxft-dev \
    libfontconfig1-dev \
    git \
    meson \
    ninja-build

# Создание временной директории
WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"
echo "Рабочая директория: $WORK_DIR"

# Клонирование репозитория ly
echo "Клонирование репозитория ly..."
git clone --recursive https://github.com/nullgemm/ly.git
cd ly

# Компиляция
echo "Компиляция ly..."
meson build
ninja -C build

# Установка
echo "Установка ly..."
sudo ninja -C build install

# Создание systemd сервиса
echo "Создание systemd сервиса..."
sudo tee /etc/systemd/system/ly.service > /dev/null <<EOF
[Unit]
Description=ly login manager
After=systemd-user-sessions.service plymouth-quit-wait.service
Before=graphical-session.target
Conflicts=getty@tty1.service

[Service]
Type=idle
Restart=always
RestartSec=1
ExecStart=/usr/local/bin/ly
StandardInput=tty
StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes

[Install]
Alias=display-manager.service
WantedBy=graphical-session.target
EOF

# Настройка конфигурации ly
echo "Настройка конфигурации ly..."
sudo mkdir -p /etc/ly
sudo tee /etc/ly/config.ini > /dev/null <<EOF
# Конфигурационный файл ly

# Автоматический запуск Xorg
x11_enabled = true

# Автоматический запуск Wayland
wayland_enabled = true

# Тема (default, dark, light)
theme = default

# Язык интерфейса
lang = en

# Автоматический вход (оставьте пустым для отключения)
auto_login = false
auto_login_user =

# Показывать список пользователей
show_user_list = true

# Показывать список сессий
show_session_list = true
EOF

# Отключение текущего менеджера входа (если есть)
echo "Отключение текущего менеджера входа..."
sudo systemctl disable gdm3 lightdm sddm gdm --quiet 2>/dev/null || true

# Включение ly
echo "Включение ly..."
sudo systemctl enable ly.service

# Настройка прав доступа
echo "Настройка прав доступа..."
sudo chmod +x /usr/local/bin/ly

echo ""
echo "=== Установка завершена успешно! ==="
echo ""
echo "Для применения изменений перезагрузите систему:"
echo "sudo reboot"
echo ""
echo "После перезагрузки ly будет запускаться автоматически."
echo "Если возникнут проблемы, можно запустить ly вручную командой:"
echo "sudo systemctl start ly"
echo ""
echo "Логи можно посмотреть командой:"
echo "journalctl -u ly.service"
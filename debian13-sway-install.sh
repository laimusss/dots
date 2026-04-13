#!/usr/bin/env bash
set -euo pipefail

# 🔒 Проверка прав запуска
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Пожалуйста, запустите скрипт с правами root: sudo bash $0"
    exit 1
fi

# Определяем оригинального пользователя (если запуск через sudo)
ORIGINAL_USER="${SUDO_USER:-$(whoami)}"

echo "🔄 Обновление списков пакетов..."
apt update -y

echo "📦 Установка пакетов..."
apt install -y \
    sway \
    wayland \
    wofi \
    alacritty \
    lxappearance \
    thunar thunar-archive-plugin \
    gvfs-backends arandr \
    pipewire pipewire-pulse wireplumber pavucontrol \
    bluez \
    swaybg swayidle swaylock \
    mako grim wl-clipboard bemenu \
    waybar unzip playerctl xdg-user-dirs \
    fonts-font-awesome fonts-firacode \
    curl ffmpeg mpv micro dialog

echo "🔌 Включение и запуск служб..."
systemctl enable --now bluetooth pipewire pipewire-pulse wireplumber

echo "📁 Настройка пользовательских директорий..."
if [ "$ORIGINAL_USER" = "root" ]; then
    echo "⚠️  Предупреждение: Скрипт запущен напрямую от root. Стандартные папки будут созданы в 
/root."
    xdg-user-dirs-update --force
else
    echo "👤 Создание директорий для пользователя: $ORIGINAL_USER"
    sudo -u "$ORIGINAL_USER" xdg-user-dirs-update --force
fi

echo ""
echo "✅ Установка успешно завершена!"
echo "💡 Следующие шаги:"
echo "   1. Скопируйте конфигурационные файлы в ~/.config/ (sway, waybar, mako, wofi и т.д.)"
echo "   2. Настройте mako для уведомлений"
echo "   3. Перезагрузите систему: sudo reboot"
echo "   4. После перезагрузки выполните: sway"

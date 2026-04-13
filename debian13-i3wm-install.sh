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
    xserver-xorg-core \
    xinit \
    i3 \
    lxappearance \
    thunar thunar-archive-plugin \
    gvfs-backends arandr xfce4-power-manager \
    alacritty \
    pipewire pipewire-pulse wireplumber pavucontrol \
    bluez \
    feh \
    rofi dunst polybar picom unzip playerctl scrot xdg-user-dirs \
    fonts-font-awesome fonts-firacode \
    emptty \
    curl ffmpeg mpv micro dialog

echo "🔌 Включение и запуск служб..."
systemctl enable --now bluetooth pipewire pipewire-pulse wireplumber emptty

echo "📁 Настройка пользовательских директорий..."
if [ "$ORIGINAL_USER" = "root" ]; then
    echo "⚠️  Предупреждение: Скрипт запущен напрямую от root. Стандартные папки будут созданы в /root."
    xdg-user-dirs-update --force
else
    echo "👤 Создание директорий для пользователя: $ORIGINAL_USER"
    sudo -u "$ORIGINAL_USER" xdg-user-dirs-update --force
fi

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
cd /home/$USER/.themes && git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git && cd Orchis-theme/ && bash ./install.sh -c dark -s compact --tweaks dracula --round 3 && cd

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
cd /home/$USER/.icons && git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git && cd Tela-circle-icon-theme/ && bash ./install.sh dracula -c && cd

echo "Themes & Icons Installed!"

echo ""
echo "✅ Установка успешно завершена!"
echo "💡 Следующие шаги:"
echo "   1. Скопируйте конфигурационные файлы в ~/.config/ (i3, picom, polybar, dunst и т.д.)"
echo "   2. Убедитесь, что lightdm использует GTK-греетер: sudo dpkg-reconfigure lightdm"
echo "   3. Перезагрузите систему: sudo reboot"

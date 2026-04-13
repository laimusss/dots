#!/usr/bin/env bash
set -euo pipefail

# 🔒 Проверка прав запуска
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Пожалуйста, запустите скрипт с правами root: sudo bash $0"
    exit 1
fi

# Определяем оригинального пользователя (если запуск через sudo)
ORIGINAL_USER="${SUDO_USER:-$(whoami)}"

# Определяем директорию, где находится сам скрипт
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Обновление списков пакетов..."
apt update -y

echo "📦 Установка пакетов..."
apt install -y \
    xserver-xorg-core \
    xinit \
    xutils \
    i3 \
    lxappearance \
    pcmanfm \
    gvfs-backends arandr xfce4-power-manager \
    alacritty \
    pipewire pipewire-pulse wireplumber pavucontrol \
    bluez \
    feh \
    rofi dunst polybar picom playerctl scrot xdg-user-dirs \
    fonts-font-awesome fonts-firacode \
    emptty \
    curl ffmpeg mpv micro dialog

echo "🔌 Включение и запуск служб..."
systemctl enable --now bluetooth emptty@tty8

echo "📁 Настройка пользовательских директорий..."
if [ "$ORIGINAL_USER" = "root" ]; then
    echo "⚠️  Предупреждение: Скрипт запущен напрямую от root. Стандартные папки будут созданы в 
/root."
    xdg-user-dirs-update --force
else
    echo "👤 Создание директорий для пользователя: $ORIGINAL_USER"
    sudo -u "$ORIGINAL_USER" xdg-user-dirs-update --force
fi

# 🎨 Установка тем и иконок
echo ""
echo "🎨 Установка тем и иконок..."

# === THEMES ===
themes_dir="/home/$ORIGINAL_USER/.themes"

if [ ! -d "$themes_dir" ]; then
    echo "📁 Создание директории тем: $themes_dir"
    mkdir -p "$themes_dir"
else
    echo "✅ Директория $themes_dir уже существует."
fi

echo "⬇️  Клонирование репозитория Orchis theme..."
cd "$themes_dir" || exit 1
git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git
cd Orchis-theme/ || exit 1
bash ./install.sh -c dark -s compact --tweaks dracula --round 1

# Возвращаемся в домашнюю директорию
cd /home/"$ORIGINAL_USER" || exit 1

# === ICONS ===
icons_dir="/home/$ORIGINAL_USER/.icons"

if [ ! -d "$icons_dir" ]; then
    echo "📁 Создание директории иконок: $icons_dir"
    mkdir -p "$icons_dir"
else
    echo "✅ Директория $icons_dir уже существует."
fi

echo "⬇️  Клонирование репозитория Tela-circle icons..."
cd "$icons_dir" || exit 1
git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git
cd Tela-circle-icon-theme/ || exit 1
bash ./install.sh dracula -c

# Возвращаемся в домашнюю директорию
cd /home/"$ORIGINAL_USER" || exit 1

echo ""
echo "🎉 Themes & Icons установлены!"

# 📋 Копирование конфигурационных файлов
echo ""
echo "📋 Копирование конфигурационных файлов..."

if [ -d "$SCRIPT_DIR/.config" ]; then
    echo "📂 Найдена папка .config в директории скрипта: $SCRIPT_DIR/.config"
    if [ "$ORIGINAL_USER" = "root" ]; then
        cp -rf "$SCRIPT_DIR/.config" /root/
        echo "✅ Конфигурации скопированы в /root/.config/"
    else
        cp -rf "$SCRIPT_DIR/.config" /home/"$ORIGINAL_USER"/
        echo "✅ Конфигурации скопированы в /home/$ORIGINAL_USER/.config/"
    fi
else
    echo "⚠️  Папка .config не найдена в директории скрипта: $SCRIPT_DIR"
    echo "   Пропускаем копирование конфигураций."
fi

echo ""
echo "✅ Установка успешно завершена!"

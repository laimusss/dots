#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Запустите с правами root: sudo bash $0"
    exit 1
fi

ORIGINAL_USER="${SUDO_USER:-$(whoami)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Проверка non-free репозитория..."
if ! grep -q "non-free" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    echo "deb http://deb.debian.org/debian $(cat /etc/debian_version | cut -d. -f1) main non-free 
non-free-firmware" >> /etc/apt/sources.list
    echo "✅ Добавлен non-free репозиторий"
fi

echo "🔄 Обновление..."
apt update -y

echo "📦 Установка пакетов..."

PACKAGES=(
    # ═══ УТИЛИТЫ ═══
    xserver-xorg-core
    x11-utils
    xdg-utils
    xdg-user-dirs
    curl
    wget
    git
    vim
    micro
    dialog

    # ═══ ОКОННЫЙ МЕНЕДЖЕР ═══
    i3
    i3lock

    # ═══ ТЕРМИНАЛ И УТИЛИТЫ ═══
    alacritty
    rofi
    dunst
    polybar
    picom
    scrot
    feh
    playerctl

    # ═══ ГРАФИКА AMD VEGA 8 ═══
    xserver-xorg-video-amdgpu
    mesa-vulkan-drivers
    libgl1-mesa-dri
    va-driver-all
    vainfo

    # ═══ ВВОД ═══
    xserver-xorg-input-libinput

    # ═══ СЕТЬ ═══
    network-manager

    # ═══ АУДИО ═══
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol
    alsa-utils

    # ═══ BLUETOOTH ═══
    bluez
    blueman

    # ═══ МОНИТОРИНГ ═══
    lm-sensors
    htop

    # ═══ ФАЙЛЫ ═══
    ntfs-3g
    udiskie

    # ═══ ЯРКОСТЬ ═══
    brightnessctl

    # ═══ ПАРОЛИ ═══
    gnome-keyring
    libsecret-tools

    # ═══ ФОНТЫ ═══
    fonts-font-awesome
    fonts-firacode
    fonts-noto

    # ═══ АРХИВАТОРЫ ═══
    p7zip-full
    unzip
    zip
    rar
    unrar

    # ═══ МУЛЬТИМЕДИА ═══
    ffmpeg
    mpv

    # ═══ ТЕМЫ И УТИЛИТЫ ═══
    lxappearance
    gtk2-engines
    gtk3-nocsd
    sassc
    pcmanfm
    gvfs-backends
    gvfs-fuse
    arandr
    xfce4-power-manager

    # ═══ СТАРТОВЫЙ МЕНЕДЖЕР ═══
    emptty
)

apt install -y "${PACKAGES[@]}"

# ═══════════════════════════════════════════════════════════════
#  СЛУЖБЫ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "⚙️ Включение служб..."

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable emptty@tty8

systemctl start NetworkManager
systemctl start bluetooth

# ═══════════════════════════════════════════════════════════════
#  ТЕМЫ И ИКОНКИ
# ═══════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════
#  КОНФИГИ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📋 Копирование конфигов..."

if [ -d "$SCRIPT_DIR/.config" ]; then
    cp -rf "$SCRIPT_DIR/.config" "$USER_HOME/"
    chown -R "$ORIGINAL_USER:$ORIGINAL_USER" "$USER_HOME/.config"
fi

xdg-user-dirs-update --force
usermod -a -G video,audio,input,netdev,wheel,fuse "$ORIGINAL_USER" 2>/dev/null || true

update-initramfs -u

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  ✅ Готово! Ребут: sudo reboot                ║"
echo "╚════════════════════════════════════════════════╝"

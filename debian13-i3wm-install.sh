#!/usr/bin/env bash
set -euo pipefail

# 🔒 Проверка прав запуска
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Запустите с правами root: sudo bash $0"
    exit 1
fi

ORIGINAL_USER="${SUDO_USER:-$(whoami)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Обновление..."
apt update -y

# ═══════════════════════════════════════════════════════════════
#  ТОЛЬКО НЕОБХОДИМЫЕ ПАКЕТЫ ДЛЯ THINKPAD T495
# ═══════════════════════════════════════════════════════════════

echo "📦 Установка пакетов..."

apt install -y \

    # ═══ ОСНОВА ═══
    xserver-xorg-core \
    xinit \
    x11-xserver-utils \
    x11-utils \
    xdg-utils \
    xdg-user-dirs \
    \

    # ═══ ОКОННЫЙ МЕНЕДЖЕР ═══
    i3 \
    i3lock \
    \

    # ═══ ТЕРМИНАЛ И УТИЛИТЫ ═══
    alacritty \
    rofi \
    dunst \
    polybar \
    picom \
    scrot \
    feh \
    playerctl \
    curl \
    wget \
    git \
    vim \
    micro \
    dialog \
    \

    # ═══ ГРАФИКА AMD VEGA 8 ═══
    xserver-xorg-video-amdgpu \
    xserver-xorg-video-ati \
    mesa-vulkan-drivers \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    va-driver-all \
    vainfo \
    \

    # ═══ ВВОД (ТАЧПАД) ═══
    xserver-xorg-input-libinput \
    \

    # ═══ СЕТЬ (Wi-Fi ATHEROS + Ethernet Realtek) ═══
    network-manager \
    firmware-atheros \
    firmware-realtek \
    iw \
    iwd \
    \

    # ═══ АУДИО (Realtek ALC + DSP AMD) ═══
    pipewire \
    pipewire-pulse \
    wireplumber \
    pavucontrol \
    alsa-utils \
    firmware-sof-audio \
    \

    # ═══ BLUETOOTH ═══
    bluez \
    blueman \
    \

    # ═══ ЭНЕРГОПОТРЕБЛЕНИЕ (Ryzen специфика)) ═══
    thermald \
    tlp \
    tlp-rdw \
    auto-cpufreq \
    cpufrequtils \
    acpi-support \
    acpi \
    \

    # ═══ МОНИТОРИНГ ═══
    lm-sensors \
    htop \
    \

    # ═══ ФАЙЛОВАЯ СИСТЕМА ═══
    ntfs-3g \
    \

    # ═══ ЯРКОСТЬ ЭКРАНА ═══
    brightnessctl \
    light \
    \
    
    # ═══ ПАРОЛИ ═══
    gnome-keyring \
    libsecret-tools \
    \

    # ═══ ФОНТЫ ═══
    fonts-font-awesome \
    fonts-firacode \
    fonts-noto \
    \

    # ═══ АРХИВАТОРЫ ═══
    p7zip-full \
    unzip \
    zip \
    \

    # ═══ МУЛЬТИМЕДИА ═══
    ffmpeg \
    mpv \
    \

    # ═══ ТЕМЫ И ИКОНКИ ═══
    lxappearance \
    pcmanfm \
    gvfs-backends \
    arandr \
    xfce4-power-manager \
    \

    # ═══ СТАРТОВЫЙ МЕНЕДЖЕР ═══
    emptty

# ═══════════════════════════════════════════════════════════════
#  СЛУЖБЫ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "⚙️ Включение служб..."

systemctl enable NetworkManager
systemctl start NetworkManager

systemctl enable bluetooth
systemctl start bluetooth

systemctl enable tlp
systemctl mask bluetooth    # маска для экономии батареи

systemctl enable thermald
systemctl start thermald

systemctl enable auto-cpufreq
systemctl start auto-cpufreq

systemctl enable emptty@tty8

# ═══════════════════════════════════════════════════════════════
#  XORG КОНФИГ ДЛЯ AMD VEGA 8
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🖥️ Настройка Xorg для AMD..."

mkdir -p /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/20-amdgpu.conf << 'EOF'
Section "Device"
    Identifier "AMD Graphics"
    Driver "amdgpu"
    Option "TearFree" "true"
    Option "DRI" "3"
EndSection
EOF

# ═══════════════════════════════════════════════════════════════
#  TLP КОНФИГ ДЛЯ AMD RYZEN
# ═══════════════════════════════════════════════════════════════

echo ""
echo "⚡ Настройка TLP..."

mkdir -p /etc/tlp.d

cat > /etc/tlp.d/99-t495.conf << 'EOF'
# Lenovo ThinkPad T495 (AMD Ryzen 5 3500U)
CPU_SCALING_GOVERNOR_ON_BAT=schedutil
CPU_SCALING_GOVERNOR_ON_AC=performance
RADEON_DPM_PERF_LEVEL_ON_BAT=low
RADEON_DPM_PERF_LEVEL_ON_AC=auto
SATA_ALPM_ON_BAT=min_power
WIFI_PWR_ON_BAT=1
USB_AUTOSUSPEND=1
EOF

tlp start

# ═══════════════════════════════════════════════════════════════
#  ТЕМЫ И ИКОНКИ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🎨 Установка тем..."

USER_HOME="/home/$ORIGINAL_USER"
[ "$ORIGINAL_USER" = "root" ] && USER_HOME="/root"

# Themes
mkdir -p "$USER_HOME/.themes"
cd "$USER_HOME/.themes" || exit 1
git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git
cd Orchis-theme/
bash ./install.sh -c dark -s compact --tweaks dracula --round 1

# Icons
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

# Пользовательские директории
xdg-user-dirs-update --force

# Права
usermod -a -G video,audio,input,netdev,wheel "$ORIGINAL_USER" 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════
#  ФИНАЛ
# ═══════════════════════════════════════════════════════════════

update-initramfs -u

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  ✅ Готово! Реbooted: sudo reboot             ║"
echo "╚════════════════════════════════════════════════╝"

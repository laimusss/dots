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
    xerver-xorg-core
    x11-utils
    xdg-utils
    xdg-user-dirs
    curl
    wget
    git
    vim
    micro
    dialog
    bc

    # ═══ ОКОННЫЙ МЕНЕДЖЕР ═══
    i3
    i3lock
    i3status

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
    libgl1-mesa-glx
    va-driver-all
    vainfo

    # ═══ ВВОД ═══
    xserver-xorg-input-libinput

    # ═══ СЕТЬ ═══
    network-manager
    iwd
    firmware-atheros
    firmware-realtek
    sof-firmware

    # ═══ АУДИО ═══
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol
    alsa-utils

    # ═══ BLUETOOTH ═══
    bluez
    blueman

    # ═══ ЭНЕРГОПОТРЕБЛЕНИЕ ═══
    thermald
    tlp
    tlp-rdw
    cpufrequtils
    acpi-support
    acpi

    # ═══ МОНИТОРИНГ ═══
    lm-sensors
    htop

    # ═══ ФАЙЛЫ ═══
    ntfs-3g
    udiskie

    # ═══ ЯРКОСТЬ ═══
    brightnessctl

    # ═══ УВЕДОМЛЕНИЯ ═══
    libnotify-bin
    notification-daemon

    # ═══ ПАРОЛИ ═══
    gnome-keyring
    libsecret-tools

    # ═══ ФОНТЫ ═══
    fonts-font-awesome
    fonts-firacode
    fonts-noto-color-emoji

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
#  AUTO-CPUFREQ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "⚡ Установка auto-cpufreq..."

if ! command -v auto-cpufreq &> /dev/null; then
    cd /tmp || exit 1
    git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq/
    bash auto-cpufreq-installer
    systemctl enable auto-cpufreq
    systemctl start auto-cpufreq
    cd "$SCRIPT_DIR" || exit 1
fi

# ═══════════════════════════════════════════════════════════════
#  СЛУЖБЫ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "⚙️ Включение служб..."

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable tlp
systemctl enable thermald
systemctl enable emptty@tty8
systemctl mask bluetooth

systemctl start NetworkManager
systemctl start bluetooth
systemctl start tlp
systemctl start thermald

# ═══════════════════════════════════════════════════════════════
#  XORG КОНФИГ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🖥️ Настройка Xorg..."

mkdir -p /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/20-amdgpu.conf << 'EOF'
Section "Device"
    Identifier "AMD Graphics"
    Driver "amdgpu"
    Option "TearFree" "true"
    Option "DRI" "3"
EndSection
EOF

cat > /etc/X11/xorg.conf.d/30-keyboard.conf << 'EOF'
Section "InputClass"
    Identifier "keyboard defaults"
    MatchIsKeyboard "on"
    Option "XkbLayout" "us,ru"
    Option "XkbOptions" "grp:alt_shift_toggle"
EndSection
EOF

# ═══════════════════════════════════════════════════════════════
#  TLP КОНФИГ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "⚡ Настройка TLP..."

mkdir -p /etc/tlp.d

cat > /etc/tlp.d/99-t495.conf << 'EOF'
CPU_SCALING_GOVERNOR_ON_BAT=schedutil
CPU_SCALING_GOVERNOR_ON_AC=performance
RADEON_DPM_PERF_LEVEL_ON_BAT=low
RADEON_DPM_PERF_LEVEL_ON_AC=auto
SATA_ALPM_ON_BAT=min_power
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

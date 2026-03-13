#!/bin/bash
# Скрипт установки и настройки Sway на Debian 13 (Trixie)
# Запускать от обычного пользователя с правами sudo

set -e  # Прерывать выполнение при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции для красивого вывода
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка, что скрипт не запущен от root
if [ "$EUID" -eq 0 ]; then
    error "Пожалуйста, не запускайте этот скрипт от root. Используйте обычного пользователя с правами sudo."
    exit 1
fi

# Проверка наличия sudo
if ! command -v sudo &> /dev/null; then
    error "sudo не установлен. Установите sudo и добавьте пользователя в sudoers."
    exit 1
fi

# Проверка возможности использования sudo
if ! sudo -v; then
    error "Нет прав sudo. Убедитесь, что пользователь имеет права sudo."
    exit 1
fi

# Обновление списка пакетов
info "Обновление списка пакетов..."
sudo apt update

# Установка необходимых пакетов
info "Установка Sway, LightDM, Waybar, Alacritty и вспомогательных утилит..."
sudo apt install -y sway lightdm waybar alacritty brightnessctl \
    foot xdg-desktop-portal-wlr grim slurp wl-clipboard \
    fonts-noto fonts-noto-cjk fonts-noto-color-emoji \
    mesa-utils mesa-utils-extra libgl1-mesa-dri

# Добавление пользователя в группы для доступа к устройствам
info "Добавление пользователя в группы input, video и seat..."
sudo usermod -aG input,video,seat "$USER"

# Создание конфигурационных директорий, если их нет
info "Создание директорий конфигурации..."
mkdir -p ~/.config/sway
mkdir -p ~/.config/waybar
mkdir -p ~/.config/alacritty

# Функция для копирования конфига с резервным копированием
backup_and_copy() {
    local src=$1
    local dst=$2
    if [ -f "$dst" ]; then
        cp "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
        warn "Создана резервная копия $dst"
    fi
    cp "$src" "$dst"
}

# Настройка конфигурации Sway
info "Настройка конфигурации Sway..."

# Создание временного файла конфигурации Sway
cat > /tmp/sway-config << 'EOF'
# Sway конфигурационный файл
# Основные настройки

set $mod Mod4   # Super ключ
set $left Left
set $down Down
set $up Up
set $right Right

# Ввод: клавиатура, мышь, тачпад
input type:keyboard {
    xkb_layout us,ru
    xkb_options grp:alt_shift_toggle
}

input type:touchpad {
    tap enabled
    natural_scroll enabled
    dwt enabled
    scroll_factor 0.5
}

# Настройки вывода (монитора)
output * bg ~/wallpaper.jpg fill

# Запуск приложений при старте
exec_always {
    # Waybar
    waybar &
    # Настройка яркости клавиатуры при старте (опционально)
    brightnessctl -d tpacpi::kbd_backlight set 50% || true
}

# Бинды клавиш
# Переключение окон
bindsym $mod+Return exec alacritty
bindsym $mod+Shift+q kill
bindsym $mod+d exec dmenu_run

# Фокус и перемещение окон
bindsym $mod+$left focus left
bindsym $mod+$down focus down
bindsym $mod+$up focus up
bindsym $mod+$right focus right
bindsym $mod+Shift+$left move left
bindsym $mod+Shift+$down move down
bindsym $mod+Shift+$up move up
bindsym $mod+Shift+$right move right

# Рабочие пространства
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5

# Режим ресайза
bindsym $mod+r mode resize
mode resize {
    bindsym $left resize shrink width 10px
    bindsym $down resize grow height 10px
    bindsym $up resize shrink height 10px
    bindsym $right resize grow width 10px
    bindsym Return mode default
    bindsym Escape mode default
}

# Управление яркостью экрана (ThinkPad T495)
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86MonBrightnessUp exec brightnessctl set +5%

# Управление подсветкой клавиатуры (ThinkPad)
bindsym XF86KbdBrightnessDown exec brightnessctl -d tpacpi::kbd_backlight set 10%-
bindsym XF86KbdBrightnessUp exec brightnessctl -d tpacpi::kbd_backlight set +10%

# Громкость (опционально)
bindsym XF86AudioLowerVolume exec amixer set Master 5%-
bindsym XF86AudioRaiseVolume exec amixer set Master 5%+
bindsym XF86AudioMute exec amixer set Master toggle

# Перезагрузка и выход
bindsym $mod+Shift+c reload
bindsym $mod+Shift+e exec swaynag -t warning -m 'Вы действительно хотите выйти из Sway?' -b 'Да, выйти' 'swaymsg exit'

# Цвета (опционально)
default_border pixel 2
default_floating_border pixel 2
focus_follows_mouse yes

# Статусбар (уже запускается waybar через exec_always, но можно и так)
bar {
    position top
    # status_command while date; do sleep 1; done  # не используется, если есть waybar
}
EOF

backup_and_copy /tmp/sway-config ~/.config/sway/config
rm /tmp/sway-config

# Базовая конфигурация Waybar (можно улучшить, но для начала сойдёт)
info "Создание базовой конфигурации Waybar..."
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["battery", "pulseaudio", "network", "tray"],
    "clock": {
        "format": "{:%H:%M   %d.%m.%Y}",
        "tooltip-format": "{:%Y-%m-%d | %H:%M}"
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""],
        "states": {
            "warning": 30,
            "critical": 15
        }
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "Muted",
        "format-icons": ["", "", ""]
    },
    "network": {
        "format-wifi": "{essid} ({signalStrength}%)",
        "format-ethernet": "Ethernet",
        "format-disconnected": "Disconnected"
    }
}
EOF

# Конфигурация Alacritty (простая)
info "Создание конфигурации Alacritty..."
cat > ~/.config/alacritty/alacritty.yml << 'EOF'
window:
  opacity: 0.9
  padding:
    x: 5
    y: 5
font:
  normal:
    family: "Noto Mono"
  size: 10
colors:
  primary:
    background: '#1e1e2e'
    foreground: '#cdd6f4'
  normal:
    black:   '#45475a'
    red:     '#f38ba8'
    green:   '#a6e3a1'
    yellow:  '#f9e2af'
    blue:    '#89b4fa'
    magenta: '#f5c2e7'
    cyan:    '#94e2d5'
    white:   '#bac2de'
  bright:
    black:   '#585b70'
    red:     '#f38ba8'
    green:   '#a6e3a1'
    yellow:  '#f9e2af'
    blue:    '#89b4fa'
    magenta: '#f5c2e7'
    cyan:    '#94e2d5'
    white:   '#a6adc8'
EOF

# Настройка LightDM для автоматического запуска Sway
info "Настройка LightDM..."
# Убедимся, что сессия Sway зарегистрирована
if [ ! -f /usr/share/way-sessions/sway.desktop ]; then
    sudo cp /usr/share/wayland-sessions/sway.desktop /usr/share/way-sessions/ 2>/dev/null || true
fi

# Включаем LightDM, если он не включён
sudo systemctl enable lightdm.service

# Переключение на LightDM, если используется другой DM
if systemctl is-active --quiet gdm; then
    warn "Обнаружен GDM. Отключаем GDM и включаем LightDM..."
    sudo systemctl disable gdm
    sudo systemctl enable lightdm
    sudo systemctl stop gdm
    sudo systemctl start lightdm
fi

# Проверка наличия подсветки клавиатуры
if [ -d /sys/class/leds/tpacpi::kbd_backlight ]; then
    info "Подсветка клавиатуры ThinkPad обнаружена. Настройка завершена."
else
    warn "Не удалось найти подсветку клавиатуры ThinkPad. Возможно, путь отличается."
fi

# Добавляем пользователя в группу video, если ещё нет
sudo usermod -aG video "$USER"

info "Установка и настройка завершены."
echo -e "${GREEN}Рекомендуется перезагрузить систему, чтобы изменения вступили в силу.${NC}"
echo "После перезагрузки вы сможете войти в Sway через LightDM."
echo "Переключение раскладки: Alt+Shift"
echo "Управление яркостью экрана: клавиши Fn+F5/F6 (или XF86MonBrightness*)"
echo "Управление подсветкой клавиатуры: клавиши Fn+Space? (или XF86KbdBrightness*)"
echo "Тачпад настроен на tap-to-click и natural scroll."
EOF
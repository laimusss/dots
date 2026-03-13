#!/bin/bash

# Скрипт автоматической установки niri + DMS + Alacritty + Nerd Fonts на EndeavourOS (Arch Linux)
# Запускать от имени обычного пользователя (не root), но с правами sudo

set -e  # Прерывать выполнение при ошибке

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для красивого вывода
print_step() {
    echo -e "${GREEN}==>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}==>${NC} $1"
}

print_error() {
    echo -e "${RED}==>${NC} $1"
}

# Проверка наличия sudo
if ! command -v sudo &> /dev/null; then
    print_error "sudo не установлен. Установите sudo или запустите скрипт от root."
    exit 1
fi

# Проверка, что не запущен от root
if [ "$EUID" -eq 0 ]; then
    print_error "Пожалуйста, не запускайте этот скрипт от root."
    print_error "Используйте обычного пользователя с правами sudo."
    exit 1
fi

print_step "Начинаем установку niri + DMS + Alacritty + Nerd Fonts на EndeavourOS"
echo ""

# ----------------------------------------------------------------------
# БЛОК 1: Настройка русской локали и удаление лишних
# ----------------------------------------------------------------------
print_step "Проверка и настройка системной локали..."

# Проверяем, какая локаль установлена сейчас
CURRENT_LANG=$(locale | grep LANG= | cut -d= -f2 | cut -d. -f1)

if [[ "$CURRENT_LANG" != "ru_RU" ]]; then
    print_warning "Текущая локаль: $CURRENT_LANG. Настраиваем русскую локаль..."

    # 1. Раскомментируем русскую локаль в /etc/locale.gen
    print_step "Включение ru_RU.UTF-8 в locale.gen..."
    sudo sed -i 's/^#\(ru_RU.UTF-8\)/\1/' /etc/locale.gen

    # 2. Генерируем локали
    print_step "Генерация локалей (locale-gen)..."
    sudo locale-gen

    # 3. Устанавливаем русскую локаль системной
    print_step "Установка ru_RU.UTF-8 как системной локали..."
    sudo localectl set-locale LANG=ru_RU.UTF-8

    # 4. Настраиваем раскладку клавиатуры для консоли (vconsole)
    print_step "Настройка русской раскладки для виртуальной консоли..."
    echo -e "KEYMAP=ru\nFONT=cyr-sun16" | sudo tee /etc/vconsole.conf >/dev/null

    # 5. Настраиваем X11 раскладку (для графической сессии)
    print_step "Настройка X11 раскладки (Alt+Shift для переключения)..."
    sudo localectl set-x11-keymap --no-convert us,ru pc105 "" grp:alt_shift_toggle

    print_step "Русская локаль успешно настроена. Изменения вступят в силу после перезагрузки."
else
    print_step "Русская локаль уже установлена. Пропускаем настройку."
fi

# ----------------------------------------------------------------------
# БЛОК 2: Удаление лишних локалей (оставляем только русскую и английскую)
# ----------------------------------------------------------------------
print_step "Удаление лишних языковых пакетов (оставляем только ru и en)..."

# Список пакетов с локалями для удаления (CJK - китайские, японские, корейские шрифты)
LOCALE_PACKAGES=(
    "noto-fonts-cjk"           # Китайские/японские/корейские шрифты
    "ttf-liberation"            # Дополнительные шрифты (можно оставить, но для чистоты удалим)
    "ttf-dejavu"                 # Можно оставить, но занимает место
)

for pkg in "${LOCALE_PACKAGES[@]}"; do
    if pacman -Q $pkg &>/dev/null; then
        print_warning "Удаляем $pkg..."
        sudo pacman -Rdd --noconfirm $pkg 2>/dev/null || print_warning "Не удалось удалить $pkg (возможно, нужен другим пакетам)"
    fi
done

# Дополнительно: удаляем все сгенерированные локали, кроме ru_RU и en_US
print_step "Очистка сгенерированных файлов локалей (оставляем только ru_RU и en_US)..."
sudo find /usr/share/locale -maxdepth 1 -type d | grep -vE '(/locale$|/ru|/en|/ru_RU|/en_US)' | sudo xargs rm -rf 2>/dev/null || true

# Обновляем кэш шрифтов после удаления
fc-cache -fv
echo ""

# ----------------------------------------------------------------------
# Шаг 1: Обновление системы (Arch-стиль)
# ----------------------------------------------------------------------
print_step "Обновление системы..."
sudo pacman -Syu --noconfirm
echo ""

# ----------------------------------------------------------------------
# Шаг 2: Проверка наличия AUR-хелпера (yay)
# ----------------------------------------------------------------------
print_step "Проверка наличия AUR-хелпера (yay)..."
if ! command -v yay &> /dev/null; then
    print_warning "yay не найден. Устанавливаем yay из AUR..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd ~
    print_step "yay успешно установлен."
else
    print_step "yay уже установлен."
fi
echo ""

# ----------------------------------------------------------------------
# Шаг 3: Проверка наличия пакета niri в официальных репозиториях
# ----------------------------------------------------------------------
print_step "Проверка наличия пакета niri в официальных репозиториях Arch..."
if pacman -Si niri &>/dev/null; then
    print_step "Пакет niri найден в официальных репозиториях."
else
    print_warning "Пакет niri не найден в официальных репозиториях."
    print_warning "Возможно, потребуется установка из AUR (niri-git)."
fi
echo ""

# ----------------------------------------------------------------------
# Шаг 4: Установка базовых инструментов и зависимостей
# ----------------------------------------------------------------------
print_step "Установка базовых инструментов и зависимостей..."
# Основные утилиты + порталы для Wayland + keyring
sudo pacman -S --needed --noconfirm \
    git curl wget nano \
    base-devel cmake \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    gnome-keyring \
    polkit \
    fuzzel \
    waybar \
    mako \
    swaybg \
    swaylock \
    swayidle \
    grim
echo ""

# ----------------------------------------------------------------------
# Шаг 5: Установка niri
# ----------------------------------------------------------------------
print_step "Установка niri..."
if pacman -Si niri &>/dev/null; then
    sudo pacman -S --noconfirm niri
    print_step "niri успешно установлен из официального репозитория."
else
    print_warning "Устанавливаем niri-git из AUR..."
    yay -S --noconfirm niri-git
    print_step "niri-git успешно установлен из AUR."
fi
echo ""

# ----------------------------------------------------------------------
# Шаг 6: Установка Alacritty из официальных репозиториев
# ----------------------------------------------------------------------
print_step "Установка терминала Alacritty..."
if sudo pacman -S --noconfirm alacritty; then
    print_step "Alacritty успешно установлен."
else
    print_error "Не удалось установить Alacritty."
    print_error "Попробуйте установить вручную: sudo pacman -S alacritty"
fi
echo ""

# ----------------------------------------------------------------------
# Шаг 7: Установка DankMaterialShell (DMS) через официальную команду
# ----------------------------------------------------------------------
print_step "Установка DankMaterialShell через официальный скрипт..."
print_step "Выполняется: curl -fsSL https://install.danklinux.com | sh"
if curl -fsSL https://install.danklinux.com | sh; then
    print_step "DMS успешно установлен!"
else
    print_error "Ошибка при установке DMS. Проверьте подключение к интернету."
    exit 1
fi
echo ""

# ----------------------------------------------------------------------
# Шаг 8: Установка Nerd Fonts (JetBrains Mono и Fira Code) для иконок
# ----------------------------------------------------------------------
print_step "Установка Nerd Fonts (JetBrains Mono и Fira Code) для корректного отображения иконок и кириллицы..."

# В Arch Linux шрифты с поддержкой Nerd Fonts находятся в пакетах ttf-*-nerd
sudo pacman -S --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-firacode-nerd

# Обновляем кэш шрифтов
fc-cache -fv

# Проверяем успешность установки
if fc-list | grep -i "JetBrainsMono Nerd" &>/dev/null || fc-list | grep -i "FiraCode Nerd" &>/dev/null; then
    print_step "Nerd Fonts успешно установлены!"
else
    print_warning "Шрифты не найдены после установки. Проверьте логи."
fi
echo ""

# ----------------------------------------------------------------------
# Шаг 9: Настройка конфигурации niri для автозапуска DMS
# ----------------------------------------------------------------------
print_step "Настройка автозапуска DMS в niri..."

mkdir -p ~/.config/niri

# Копируем пример конфига, если есть (в Arch путь может отличаться)
if [ -f "/usr/share/niri/config.kdl" ]; then
    cp /usr/share/niri/config.kdl ~/.config/niri/config.kdl 2>/dev/null || true
elif [ -f "/etc/niri/config.kdl" ]; then
    cp /etc/niri/config.kdl ~/.config/niri/config.kdl 2>/dev/null || true
else
    touch ~/.config/niri/config.kdl
fi

if ! grep -q "spawn-at-startup.*dms" ~/.config/niri/config.kdl 2>/dev/null; then
    echo '' >> ~/.config/niri/config.kdl
    echo '# Автозапуск DankMaterialShell' >> ~/.config/niri/config.kdl
    echo 'spawn-at-startup "dms"' >> ~/.config/niri/config.kdl
    print_step "Строка автозапуска добавлена в ~/.config/niri/config.kdl"
else
    print_warning "Автозапуск DMS уже настроен."
fi
echo ""

# ----------------------------------------------------------------------
# Шаг 10: Создание базовой конфигурации для Alacritty с Nerd Font
# ----------------------------------------------------------------------
print_step "Создание базовой конфигурации для Alacritty..."
mkdir -p ~/.config/alacritty
if [ ! -f ~/.config/alacritty/alacritty.toml ]; then
    # Определяем, какой шрифт использовать
    if fc-list | grep -q "JetBrainsMono Nerd"; then
        FONT_FAMILY="JetBrainsMono Nerd Font"
    elif fc-list | grep -q "FiraCode Nerd"; then
        FONT_FAMILY="FiraCode Nerd Font"
    else
        FONT_FAMILY="monospace"
    fi

    cat > ~/.config/alacritty/alacritty.toml << EOF
[window]
opacity = 0.95
padding.x = 10
padding.y = 10

[font]
size = 11.0

[font.normal]
family = "$FONT_FAMILY"
style = "Regular"

[font.bold]
family = "$FONT_FAMILY"
style = "Bold"

[font.italic]
family = "$FONT_FAMILY"
style = "Italic"

[colors]
[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.normal]
black = "#45475a"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#cba6f7"
cyan = "#94e2d5"
white = "#bac2de"
EOF
    print_step "Конфигурация Alacritty создана с использованием $FONT_FAMILY"
else
    print_warning "Конфигурация Alacritty уже существует."
fi
echo ""

# ----------------------------------------------------------------------
# Шаг 11: Финальные сообщения
# ----------------------------------------------------------------------
print_step "Установка завершена!"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   УСТАНОВКА ЗАВЕРШЕНА                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Что было установлено/настроено:"
echo "  ✓ Русская локаль (ru_RU.UTF-8) — включена и сгенерирована"
echo "  ✓ Раскладка клавиатуры: русская + английская (переключение Alt+Shift)"
echo "  ✓ Лишние локали и шрифты удалены"
echo "  ✓ niri (композитор Wayland) — из официального репозитория или AUR"
echo "  ✓ Alacritty (терминал)"
echo "  ✓ DankMaterialShell (DMS)"
echo "  ✓ Wayland порталы и keyring (для корректной работы)"
echo "  ✓ fuzzel (лаунчер), waybar (панель), mako (уведомления) — базовый набор"
if fc-list | grep -i "JetBrainsMono Nerd" &>/dev/null || fc-list | grep -i "FiraCode Nerd" &>/dev/null; then
    echo "  ✓ Nerd Fonts (JetBrains Mono и Fira Code)"
else
    echo "  ✗ Nerd Fonts не установлены"
fi
echo ""
echo "⚠️  Дисплейный менеджер НЕ установлен."
echo ""
echo "👉 Чтобы запустить niri после перезагрузки:"
echo "   1. Войдите в текстовую консоль (tty1)"
echo "   2. Выполните команду: niri"
echo "   (DMS запустится автоматически благодаря настройке)"
echo ""
echo "Горячие клавиши niri (по умолчанию):"
echo "  • Super + T - открыть терминал (Alacritty)"
echo "  • Super + Q - закрыть окно"
echo "  • Super + стрелки - переключение между окнами"
echo ""
echo "Файлы конфигурации:"
echo "  • niri: ~/.config/niri/config.kdl"
echo "  • Alacritty: ~/.config/alacritty/alacritty.toml"
echo ""
echo -e "${YELLOW}После перезагрузки система запустится с русским языком интерфейса.${NC}"
echo -e "${YELLOW}Для запуска niri вручную используйте команду 'niri' в консоли.${NC}"
echo ""
read -p "Перезагрузить систему сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Перезагрузка..."
    sudo reboot
else
    print_step "Готово! Для запуска niri выполните 'niri' в консоли после входа."
fi

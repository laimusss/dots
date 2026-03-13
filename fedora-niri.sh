#!/bin/bash

# Скрипт автоматической установки niri + ly + DMS + Alacritty + Nerd Fonts (JetBrains Mono и Fira Code) на Fedora 43 Minimal
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

print_step "Начинаем установку niri + ly + DMS + Alacritty + Nerd Fonts (JetBrains Mono и Fira Code) на Fedora 43 Minimal"
echo ""

# Шаг 1: Обновление системы
print_step "Обновление системы..."
sudo dnf upgrade --refresh -y
echo ""

# Шаг 1.1: Решение проблемы с геоблоком Cisco OpenH264 (для РФ)
print_step "Проверка и исправление проблемы с репозиторием Cisco OpenH264 (геоблок)..."

# Отключаем проблемный репозиторий Cisco
if [ -f /etc/yum.repos.d/fedora-cisco-openh264.repo ]; then
    print_warning "Отключаем репозиторий fedora-cisco-openh264 (геоблок)..."
    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=0 2>/dev/null || \
        sudo sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/fedora-cisco-openh264.repo
fi

# Заменяем openh264 на noopenh264 (пустышку), если пакет установлен
if rpm -q openh264 &>/dev/null; then
    print_warning "Заменяем openh264 на noopenh264..."
    sudo dnf swap -y openh264 noopenh264 --allowerasing || \
        print_warning "Не удалось заменить openh264, но это не критично"
else
    print_step "Пакет openh264 не установлен, пропускаем замену"
fi

# Маскируем OpenH264 в Flatpak (чтобы не блокировал установку приложений)
if command -v flatpak &>/dev/null; then
    print_step "Маскируем OpenH264 в Flatpak..."
    sudo flatpak mask --system org.freedesktop.Platform.openh264 2>/dev/null || true
fi

# Добавляем глобальное исключение для openh264 в DNF (на всякий случай)
if ! grep -q "exclude=openh264" /etc/dnf/dnf.conf 2>/dev/null; then
    echo "exclude=openh264*" | sudo tee -a /etc/dnf/dnf.conf >/dev/null
    print_step "Добавлено глобальное исключение для openh264 в dnf.conf"
fi

print_step "Проблема с геоблоком Cisco OpenH264 обработана"
echo ""

# Шаг 2: Установка базовых инструментов
print_step "Установка базовых инструментов..."
sudo dnf install -y nano git curl wget
echo ""

# Шаг 3: Включение репозитория COPR для niri
print_step "Включение репозитория yalter/niri (официальный репозиторий niri)..."
sudo dnf copr enable -y yalter/niri
echo ""

# Шаг 4: Установка niri и необходимых зависимостей
print_step "Установка niri и библиотек..."
sudo dnf install -y niri mesa-libEGL
echo ""

# Шаг 5: Включение репозитория COPR для ly
print_step "Включение репозитория atim/ly (для установки display manager ly)..."
sudo dnf copr enable -y atim/ly
echo ""

# Шаг 6: Установка ly
print_step "Установка display manager ly..."
sudo dnf install -y ly
echo ""

# Шаг 7: Включение сервиса ly
print_step "Включение сервиса ly для автозапуска при загрузке..."

# Отключаем другие display manager'ы, если они есть
for dm in gdm sddm lightdm xdm; do
    if systemctl is-active --quiet $dm 2>/dev/null; then
        print_warning "Отключаем $dm..."
        sudo systemctl disable $dm
    fi
done

# Включаем ly
sudo systemctl enable ly.service
echo ""

# Шаг 8: Установка Alacritty (терминал) из официальных репозиториев Fedora
print_step "Установка терминала Alacritty из официальных репозиториев..."
if sudo dnf install -y alacritty; then
    print_step "Alacritty успешно установлен из официальных репозиториев Fedora"
else
    print_error "Не удалось установить Alacritty из официальных репозиториев."
    print_error "Проверьте подключение к интернету или установите вручную позже."
fi
echo ""

# Шаг 9: Установка DankMaterialShell (DMS) через официальный скрипт
print_step "Установка DankMaterialShell через официальный скрипт с GitHub..."

# Проверяем доступность официального скрипта
if curl -s --head https://raw.githubusercontent.com/AvengeMedia/DankMaterialShell/main/install.sh | head -n 1 | grep "200" > /dev/null; then
    print_step "Официальный скрипт доступен. Запускаем установку..."
    
    # Загружаем и запускаем официальный скрипт установки
    bash <(curl -s https://raw.githubusercontent.com/AvengeMedia/DankMaterialShell/main/install.sh)
    
    # Проверяем успешность установки
    if command -v dms &> /dev/null; then
        print_step "DMS успешно установлен!"
    else
        print_warning "DMS установлен, но команда 'dms' не найдена в PATH"
    fi
else
    print_error "Официальный скрипт DMS недоступен по ссылке"
    print_error "Пожалуйста, проверьте: https://github.com/AvengeMedia/DankMaterialShell"
    print_error "Вы можете установить DMS вручную позже."
fi
echo ""

# Шаг 10: Установка Nerd Fonts (только JetBrains Mono и Fira Code)
print_step "Установка Nerd Fonts (JetBrains Mono и Fira Code) для корректного отображения иконок и кириллицы..."

# Включаем COPR репозиторий с Nerd Fonts
print_step "Включение репозитория skidnik/mononoki (содержит Nerd Fonts)..."
sudo dnf copr enable -y skidnik/mononoki

# Устанавливаем только JetBrains Mono Nerd Font и Fira Code Nerd Font
print_step "Установка пакетов jetbrains-mono-nerd-ttf-fonts и fira-code-nerd-ttf-fonts..."
sudo dnf install -y \
    jetbrains-mono-nerd-ttf-fonts \
    fira-code-nerd-ttf-fonts

# Обновляем кэш шрифтов
print_step "Обновление кэша шрифтов..."
fc-cache -fv

# Проверяем успешность установки
if fc-list | grep -i "nerd" | grep -E "JetBrains|Fira" > /dev/null; then
    print_step "Nerd Fonts успешно установлены!"
    print_step "Доступные Nerd Fonts:"
    fc-list | grep -i "nerd" | grep -E "JetBrains|Fira" | cut -d: -f2 | sort -u
else
    print_warning "Nerd Fonts не найдены после установки. Проверьте логи."
fi
echo ""

# Шаг 11: Настройка конфигурации niri для автозапуска DMS
print_step "Настройка автозапуска DMS в niri..."

# Создаем директорию для конфигурации
mkdir -p ~/.config/niri

# Копируем пример конфига, если есть
if [ -f "/usr/share/niri/config.kdl" ]; then
    cp /usr/share/niri/config.kdl ~/.config/niri/config.kdl 2>/dev/null || true
else
    # Создаем пустой конфиг
    touch ~/.config/niri/config.kdl
fi

# Добавляем автозапуск DMS, если его там нет
if ! grep -q "spawn-at-startup.*dms" ~/.config/niri/config.kdl 2>/dev/null; then
    echo '' >> ~/.config/niri/config.kdl
    echo '# Автозапуск DankMaterialShell' >> ~/.config/niri/config.kdl
    echo 'spawn-at-startup "dms"' >> ~/.config/niri/config.kdl
    print_step "Строка автозапуска добавлена в ~/.config/niri/config.kdl"
else
    print_warning "Автозапуск DMS уже настроен в конфиге"
fi
echo ""

# Шаг 12: Создание базовой конфигурации для Alacritty с JetBrains Mono Nerd Font
print_step "Создание базовой конфигурации для Alacritty с JetBrains Mono Nerd Font..."
mkdir -p ~/.config/alacritty
if [ ! -f ~/.config/alacritty/alacritty.toml ]; then
    cat > ~/.config/alacritty/alacritty.toml << 'EOF'
[window]
opacity = 0.95
padding.x = 10
padding.y = 10

[font]
size = 11.0

# Используем JetBrains Mono Nerd Font (с кириллицей)
[font.normal]
family = "JetBrainsMono Nerd Font"
style = "Regular"

[font.bold]
family = "JetBrainsMono Nerd Font"
style = "Bold"

[font.italic]
family = "JetBrainsMono Nerd Font"
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
    print_step "Базовая конфигурация Alacritty создана с использованием JetBrainsMono Nerd Font"
else
    print_warning "Конфигурация Alacritty уже существует"
fi
echo ""

# Шаг 13: Финальные сообщения
print_step "Установка завершена!"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   УСТАНОВКА ЗАВЕРШЕНА                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Что было установлено:"
echo "  ✓ niri (композитор Wayland)"
echo "  ✓ ly (display manager из COPR)"
echo "  ✓ Alacritty (из официальных репозиториев Fedora)"
echo "  ✓ DankMaterialShell (через официальный скрипт с GitHub)"
echo "  ✓ Nerd Fonts (с поддержкой кириллицы):"
echo "    - JetBrains Mono Nerd Font"
echo "    - Fira Code Nerd Font"
echo ""
echo "Что нужно сделать после перезагрузки:"
echo "  1. При входе в ly выберите сессию 'niri' (обычно в углу экрана)"
echo "  2. DMS должен запуститься автоматически"
echo "  3. В терминале Alacritty уже настроен JetBrainsMono Nerd Font"
echo ""
echo "Горячие клавиши niri (по умолчанию):"
echo "  • Super + T - открыть терминал (Alacritty)"
echo "  • Super + Q - закрыть окно"
echo "  • Super + стрелки - переключение между окнами"
echo ""
echo "Файлы конфигурации:"
echo "  • niri: ~/.config/niri/config.kdl"
echo "  • Alacritty: ~/.config/alacritty/alacritty.toml"
echo "  • ly: /etc/ly/config.ini"
echo ""
echo "Полезные ссылки:"
echo "  • DMS GitHub: https://github.com/AvengeMedia/DankMaterialShell"
echo "  • Документация niri: https://github.com/YaLTeR/niri"
echo "  • Nerd Fonts: https://www.nerdfonts.com/"
echo ""
echo -e "${YELLOW}После перезагрузки система запустится с графическим входом.${NC}"
echo -e "${YELLOW}Если что-то пойдет не так, вы всегда можете переключиться в TTY через Ctrl+Alt+F2${NC}"
echo ""
read -p "Перезагрузить систему сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Перезагрузка..."
    sudo reboot
else
    print_step "Готово! Для применения изменений перезагрузите систему позже."
fi
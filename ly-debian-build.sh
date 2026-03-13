#!/bin/bash
# Автоматическая установка дисплейного менеджера Ly в Debian 13 (Trixie)
# Исправлена проблема с установкой Zig: используется ручная загрузка бинарных файлов с сайта ziglang.org

set -e  # Прерывать выполнение при любой ошибке

# --- Проверка прав root ---
if [ "$EUID" -ne 0 ]; then
    echo "Пожалуйста, запустите скрипт с правами root (используйте sudo)."
    exit 1
fi

# --- Функция для вывода сообщений ---
echo_step() {
    echo
    echo "========================================"
    echo "➡️  $1"
    echo "========================================"
}

# --- 1. Подготовка: установка curl и прочих утилит ---
echo_step "Установка вспомогательных утилит (curl, xz-utils)"
apt update
apt install -y curl xz-utils build-essential libpam0g-dev libxcb-xkb-dev xauth xserver-xorg brightnessctl git

# --- 2. Ручная установка Zig ---
echo_step "Скачивание и установка последней версии Zig с официального сайта"

# Определение архитектуры системы
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ZIG_ARCH="x86_64-linux"
elif [ "$ARCH" = "aarch64" ]; then
    ZIG_ARCH="aarch64-linux"
else
    echo "Архитектура $ARCH не поддерживается скриптом для автоматической загрузки Zig."
    exit 1
fi

# Получение версии последнего стабильного релиза (можно заменить на фиксированную, например 0.13.0)
# Здесь для простоты используется фиксированная ссылка на актуальную версию 0.14.0 (проверьте актуальность на сайте)
ZIG_VERSION="0.14.0"
ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz"

# Скачивание и распаковка в /usr/local/zig
mkdir -p /usr/local/zig
curl -L "$ZIG_URL" | tar -xJ --strip-components=1 -C /usr/local/zig

# Добавление Zig в глобальный PATH (через симлинк)
ln -sf /usr/local/zig/zig /usr/local/bin/zig

# Проверка установки Zig
if ! command -v zig &> /dev/null; then
    echo "❌ Ошибка: Zig не установился."
    exit 1
fi
echo "✅ Zig установлен: $(zig version)"

# --- 3. Клонирование репозитория Ly ---
echo_step "Клонирование исходного кода Ly с Codeberg"
if [ -d "ly" ]; then
    echo "Каталог 'ly' уже существует. Обновляем..."
    cd ly
    git pull
else
    git clone https://codeberg.org/fairyglade/ly.git
    cd ly
fi

# --- 4. Компиляция Ly ---
echo_step "Компиляция Ly с помощью Zig"
zig build

# --- 5. Установка в систему (для systemd) ---
echo_step "Установка исполняемых файлов и сервисных unit-файлов"
zig build installexe -Dinit_system=systemd

# --- 6. Отключение текущего дисплейного менеджера ---
echo_step "Отключение ранее установленного дисплейного менеджера (если есть)"
DM_SERVICES=("lightdm.service" "gdm3.service" "sddm.service" "xdm.service" "nodm.service")
for dm in "${DM_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$dm"; then
        echo "Отключаю $dm"
        systemctl disable "$dm" 2>/dev/null || true
    fi
done

# --- 7. Отключение стандартного getty на tty2 ---
echo_step "Отключение getty на tty2 (чтобы освободить терминал для Ly)"
systemctl disable getty@tty2.service 2>/dev/null || echo "Сервис getty@tty2 уже отключён или не найден."

# --- 8. Включение сервиса Ly ---
echo_step "Включение сервиса Ly для запуска на tty2"
systemctl enable ly@tty2.service

# --- 9. Финальные рекомендации ---
echo_step "Установка завершена!"
cat << EOF

✅ Ly успешно скомпилирован и установлен.
✅ Zig установлен в /usr/local/zig и доступен глобально.

Что дальше?
1.  Перезагрузите систему, чтобы войти через Ly:
        sudo reboot

2.  После перезагрузки вы увидите TUI-экран входа Ly.

3.  Конфигурационный файл находится в /etc/ly/config.ini
    Отредактируйте его при необходимости.

4.  Если что-то пойдёт не так, вы всегда можете переключиться на другой TTY
    (например, Ctrl+Alt+F1) и откатить изменения.

EOF

# Спросить о перезагрузке
read -p "Хотите перезагрузить систему сейчас? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
else
    echo "Перезагрузка отложена. Не забудьте перезагрузиться позже для активации Ly."
fi
#!/bin/bash
# Автоматическая установка дисплейного менеджера Ly в Debian 13 (Trixie)
# Исправлена проблема с отсутствием пакета zig в официальных репозиториях.
# Подключается сторонний репозиторий debian.griffo.io.

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

# --- 1. Подготовка: установка curl и lsb-release (могут отсутствовать) ---
echo_step "Установка вспомогательных утилит (curl, lsb-release)"
apt update
apt install -y curl lsb-release

# --- 2. Подключение репозитория debian.griffo.io для Zig ---
echo_step "Подключение стороннего репозитория debian.griffo.io для установки Zig"
# Добавление GPG-ключа репозитория [citation:1][citation:5]
curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg
# Добавление самого репозитория в список источников APT
echo "deb https://debian.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | tee /etc/apt/sources.list.d/debian.griffo.io.list
apt update

# --- 3. Установка зависимостей (включая zig из подключенного репозитория) ---
echo_step "Установка пакетов, необходимых для сборки и работы Ly"
# Вместо 'zig' ставим 'zig-master', так как Ly требует актуальную версию (0.15.x) [citation:5]
apt install -y build-essential libpam0g-dev libxcb-xkb-dev xauth xserver-xorg brightnessctl git zig-master

# Проверка, что zig доступен в PATH после установки zig-master
if ! command -v zig &> /dev/null; then
    echo "⚠️  Команда 'zig' не найдена. Проверьте установку zig-master."
    exit 1
fi

# --- 4. Клонирование репозитория Ly ---
echo_step "Клонирование исходного кода Ly с Codeberg"
if [ -d "ly" ]; then
    echo "Каталог 'ly' уже существует. Обновляем..."
    cd ly
    git pull
else
    git clone https://codeberg.org/fairyglade/ly.git
    cd ly
fi

# --- 5. Компиляция Ly ---
echo_step "Компиляция Ly с помощью Zig"
zig build

# --- 6. Установка в систему (для systemd) ---
echo_step "Установка исполняемых файлов и сервисных unit-файлов"
zig build installexe -Dinit_system=systemd

# --- 7. Отключение текущего дисплейного менеджера ---
echo_step "Отключение ранее установленного дисплейного менеджера (если есть)"
DM_SERVICES=("lightdm.service" "gdm3.service" "sddm.service" "xdm.service" "nodm.service")
for dm in "${DM_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$dm"; then
        echo "Отключаю $dm"
        systemctl disable "$dm" 2>/dev/null || true
    fi
done

# --- 8. Отключение стандартного getty на tty2 ---
echo_step "Отключение getty на tty2 (чтобы освободить терминал для Ly)"
systemctl disable getty@tty2.service 2>/dev/null || echo "Сервис getty@tty2 уже отключён или не найден."

# --- 9. Включение сервиса Ly ---
echo_step "Включение сервиса Ly для запуска на tty2"
systemctl enable ly@tty2.service

# --- 10. Финальные рекомендации ---
echo_step "Установка завершена!"
cat << EOF

✅ Ly успешно скомпилирован и установлен.

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
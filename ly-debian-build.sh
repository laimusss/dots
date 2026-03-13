#!/bin/bash
# Автоматическая установка дисплейного менеджера Ly в Debian 13 (Trixie)
# Основано на официальной инструкции: https://github.com/fairyglade/ly

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

# --- 1. Установка зависимостей ---
echo_step "Установка пакетов, необходимых для сборки и работы Ly"
apt update
apt install -y build-essential libpam0g-dev libxcb-xkb-dev xauth xserver-xorg brightnessctl git zig

# --- 2. Клонирование репозитория ---
echo_step "Клонирование исходного кода Ly с Codeberg"
if [ -d "ly" ]; then
    echo "Каталог 'ly' уже существует. Обновляем..."
    cd ly
    git pull
else
    git clone https://codeberg.org/fairyglade/ly.git
    cd ly
fi

# --- 3. Компиляция ---
echo_step "Компиляция Ly с помощью Zig"
zig build

# --- 4. Установка в систему (для systemd) ---
echo_step "Установка исполняемых файлов и сервисных unit-файлов"
zig build installexe -Dinit_system=systemd

# --- 5. Отключение текущего дисплейного менеджера ---
echo_step "Отключение ранее установленного дисплейного менеджера (если есть)"
# Список наиболее распространённых DM
DM_SERVICES=("lightdm.service" "gdm3.service" "sddm.service" "xdm.service" "nodm.service")
for dm in "${DM_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$dm"; then
        echo "Отключаю $dm"
        systemctl disable "$dm" 2>/dev/null || true
    fi
done

# --- 6. Отключение стандартного getty на tty2 ---
echo_step "Отключение getty на tty2 (чтобы освободить терминал для Ly)"
systemctl disable getty@tty2.service 2>/dev/null || echo "Сервис getty@tty2 уже отключён или не найден."

# --- 7. Включение сервиса Ly ---
echo_step "Включение сервиса Ly для запуска на tty2"
systemctl enable ly@tty2.service

# --- 8. Финальные рекомендации ---
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
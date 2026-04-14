#!/usr/bin/bash

# Установка драйверов AMD GPU Vega 8 на Debian 13

# Проверка на sudo
if [ "$EUID" -ne 0 ]; then
    echo "Запустите скрипт с правами sudo"
    exit 1
fi

# Запрос про 32-битные драйверы
echo "=========================================="
echo " Установка AMD драйверов для Vega 8"
echo "=========================================="
echo ""
echo "Установить 32-битные (i386) драйверы?"
echo "Необходимо для некоторых игр и старых приложений"
echo ""
read -p "Введите 'y' для установки 32-битных, 'n' только для 64-битных: " -n 1 -r
echo ""

case $REPLY in
    y|Y)
        INSTALL_32BIT=true
        echo "Будут установлены 64-битные и 32-битные драйверы"
        ;;
    n|N)
        INSTALL_32BIT=false
        echo "Будут установлены только 64-битные драйверы"
        ;;
    *)
        echo "Неизвестный ответ. Устанавливаю только 64-битные."
        INSTALL_32BIT=false
        ;;
esac

echo ""

# 1. Включение 32-битной архитектуры (только если нужно)
if [ "$INSTALL_32BIT" = true ]; then
    echo "[1/3] Включение 32-битной архитектуры..."
    if dpkg --print-foreign-architectures | grep -q i386; then
        echo "      32-битная архитектура уже включена"
    else
        sudo dpkg --add-architecture i386
        sudo apt update
    fi
fi

# 2. Установка 64-битных драйверов
echo "[2/3] Установка 64-битных драйверов..."
sudo apt install -y \
    firmware-amd-graphics \
    mesa-vulkan-drivers \
    libvulkan-radeon \
    libgl1-mesa-dri \
    libglx-mesa0 \
    mesa-utils \
    libva2 \
    libva-mesa-driver \
    va-driver-all \
    mesa-va-drivers

# 3. Установка 32-битных драйверов (если выбрано)
if [ "$INSTALL_32BIT" = true ]; then
    echo "[3/3] Установка 32-битных драйверов..."
    sudo apt install -y \
        libgl1-mesa-dri:i386 \
        libglx-mesa0:i386 \
        libgl1:i386 \
        mesa-vulkan-drivers:i386 \
        libvulkan1:i386 \
        libva2:i386 \
        va-driver-all:i386 \
        mesa-va-drivers:i386
else
    echo "[3/3] Пропуск установки 32-битных драйверов"
fi

echo ""
echo "=========================================="
echo " Установка завершена!"
echo "=========================================="

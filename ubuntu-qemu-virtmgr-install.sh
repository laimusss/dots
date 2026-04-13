#!/usr/bin/env bash
set -euo pipefail

# 🔒 Проверка прав запуска
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Пожалуйста, запустите скрипт с правами root: sudo bash $0"
    exit 1
fi

# Определяем оригинального пользователя (если запуск через sudo)
ORIGINAL_USER="${SUDO_USER:-$(whoami)}"

echo "🔄 Обновление списков пакетов..."
apt-get update -y

echo "📦 Установка пакетов..."
apt-get install -y \
    qemu-system-x86 libvirt-daemon-system libvirt-clients virt-manager virtinst libosinfo-bin ovmf libvirt-dbus

echo "Включаем сервисы..."
systemctl enable --now libvirtd

echo "Добавляем юзера в группы..."
usermod -aG libvirt,kvm $USER

echo "✅ Установка успешно завершена!"
echo "💡 Следующие шаги:"
echo " Перезагрузите систему: sudo reboot"


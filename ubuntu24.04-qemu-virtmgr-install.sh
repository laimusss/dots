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
    qemu-system-x86 \
    libvirt-daemon-system \
    libvirt-clients \
    virt-manager \
    virtinst \
    libosinfo-bin \
    ovmf \
    libvirt-dbus \
    spice-vdagent \
    spice-webdavd

echo "🔄 Включаем сервисы..."
systemctl enable --now libvirtd
systemctl enable --now spice-vdagent

echo "👤 Добавляем юзера в группы..."
usermod -aG libvirt,kvm $ORIGINAL_USER

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Установка успешно завершена!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🐧 Для гостевой Linux:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat << 'EOF'
   1. Установите в гостевой системе:
      sudo apt install spice-vdagent

   2. Включите и запустите сервис:
      sudo systemctl enable --now spice-vdagent
EOF
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  Настройка VM для использования SPICE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat << 'EOF'
   Для использования буфера обмена, настройте VM
   с использованием SPICE display:

   1. Откройте virt-manager
   2. Выберите VM → Edit → Virtual Machine Settings
   3. Add Hardware → Display (SPICE)
   4. Тип: SPICE server
   5. Listen type: Listen on all addresses
   6. Password: установите пароль (опционально)
   7. Enable OpenGL: No
   8. В разделе Video выберите модель: QXL
   ------------------------------------
EOF
echo ""
echo "💡 Для применения изменений перезапустите VM"
echo ""
echo "⚠️  Не забудьте перезагрузить систему: sudo reboot"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

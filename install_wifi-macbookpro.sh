# Установка драйвера WiFi Macbook
echo ""
read -p ">>> Установить драйвер WiFi для Macbook? (y/n) " choice
echo ""
if [ "$choice" == "y" ]; then
sudo nala install -y linux-image-$(uname -r|sed 's,[^-]*-[^-]*-,,') linux-headers-$(uname -r|sed 's,[^-]*-[^-]*-,,') broadcom-sta-dkms
sudo modprobe -r b44 b43 b43legacy ssb brcmsmac bcma
sudo modprobe wl
echo ""
echo "| Драйвер установлен"
else
echo "| Установка пропущена"
fi


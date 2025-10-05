#!/bin/bash
echo ""
read -p ">>> Установить Zen-Browser? (y/n) " choice
echo ""
if [ "$choice" == "y" ]; then
sudo nala install -y zsync
bash <(curl https://updates.zen-browser.app/appimage.sh)
echo ""
echo "| Zen-Browser установлен"
else
echo "| Установка пропущена"
fi

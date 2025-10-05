#!/bin/bash

# Установка OnlyOffice
echo ""
read -p ">>> Установить OnlyOffice? (y/n) " choice
echo ""
if [ "$choice" == "y" ]; then
mkdir -p -m 700 ~/.gnupg
gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
chmod 644 /tmp/onlyoffice.gpg
sudo chown root:root /tmp/onlyoffice.gpg
sudo mv /tmp/onlyoffice.gpg /etc/apt/keyrings/onlyoffice.gpg
echo 'deb [signed-by=/etc/apt/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee -a /etc/apt/sources.list.d/onlyoffice.list
sudo nala update -y
sudo nala install -y onlyoffice-desktopeditors
echo ""
echo "| OnlyOffice установлен"
else
echo "| Установка пропущена"
fi


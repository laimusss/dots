#!/bin/bash

# xorg display server installation
sudo apt install -y xserver-xorg-core xinit
# Install i3
sudo apt install -y i3

# Installation for Appearance management
sudo apt install -y lxappearance

# File Manager
sudo apt install -y thunar thunar-archive-plugin

# Network File Tools/System Events
sudo apt install -y dialog acpi acpid gvfs-backends arandr

sudo systemctl enable acpid

# Terminal
sudo apt install -y alacritty

# Sound packages
sudo apt install -y pulseaudio pavucontrol

# Printing and bluetooth (if needed)
sudo apt install -y bluez

sudo systemctl enable bluetooth

# Desktop background browser/handler 
sudo apt install -y feh

# Packages needed i3 after installation
sudo apt install -y xfce4-power-manager rofi dunst polybar picom unzip playerctl scrot xdg-user-dirs-gtk

# AmneziaVPN packages
sudo apt install -y libxcb-cursor0 libxcb-xinerama0

# Additional Software
sudo apt install -y curl ffmpeg mpv micro

# Install fonts
sudo apt install -y fonts-font-awesome fonts-firacode

# Install Display Manager
sudo apt install -y slim

# Create folders in user directory
xdg-user-dirs-update

#Additional
source onlyoffice-install-debian.sh
source wifi-macbookpro.sh
source zen-browser-install.sh

# Finish Clean
sudo apt autopurge -y

echo "Setup Complete! Please, reboot your computer!"

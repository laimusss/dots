#!/usr/bin/bash

# Установка драйверов AMD GPU Vega 8 на Debian 13

## 1. Установка базовых драйверов

sudo apt install firmware-amd-graphics mesa-vulkan-drivers libglx-mesa0 mesa-utils libva-mesa-driver va-driver-all mesa-va-drivers

## 1. Включение 32-битной архитектуры

```bash
sudo dpkg --add-architecture i386
sudo apt update
```

## 2. Установка 32-битных драйверов AMD

### Основные 32-битные библиотеки

```bash
sudo apt install \
    libgl1-mesa-dri:i386 \
    libglx-mesa0:i386 \
    libglx0:i386 \
    libgl1:i386
```

### 32-битные Vulkan драйверы AMD

```bash
sudo apt install \
    mesa-vulkan-drivers:i386 \
    libvulkan1:i386 \
    libvulkan-radeon1:i386

### 32-битные VA-API (видео ускорение)

```bash
sudo apt install \
    libva2:i386 \
    libva-x11-1:i386 \
    mesa-va-drivers:i386

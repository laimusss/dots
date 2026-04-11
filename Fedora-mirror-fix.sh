#!/usr/bin/env bash
set -euo pipefail

# Скрипт для настройки Fedora 43:
# - Добавление RPM Fusion free и non-free
# - Замена зеркал на Яндекс
# - Отключение репозитория Cisco OpenH264 (для dnf и flatpak)

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
    log_error "Скрипт должен быть запущен с правами root (используйте sudo)."
    exit 1
fi

# Проверка версии Fedora
if ! grep -q "Fedora release 43" /etc/fedora-release 2>/dev/null; then
    log_warn "Скрипт разработан для Fedora 43, но текущая версия может отличаться."
    log_warn "Текущая: $(cat /etc/fedora-release 2>/dev/null || echo 'не определена')"
fi

# Функция добавления RPM Fusion с проверкой ключей
add_rpmfusion() {
    local releasever=$(rpm -E %fedora)
    local free_url="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${releasever}.noarch.rpm"
    local nonfree_url="https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${releasever}.noarch.rpm"

    log_info "Импорт GPG-ключей RPM Fusion..."
    rpm --import https://mirrors.rpmfusion.org/pub/RPM-GPG-KEY-rpmfusion-free-fedora 2>/dev/null || true
    rpm --import https://mirrors.rpmfusion.org/pub/RPM-GPG-KEY-rpmfusion-nonfree-fedora 2>/dev/null || true

    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        log_info "Добавление RPM Fusion free..."
        dnf install -y "$free_url"
    else
        log_info "RPM Fusion free уже установлен."
    fi

    if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        log_info "Добавление RPM Fusion nonfree..."
        dnf install -y "$nonfree_url"
    else
        log_info "RPM Fusion nonfree уже установлен."
    fi
}

# Функция замены зеркал на Яндекс
set_yandex_mirrors() {
    log_info "Настройка зеркал Яндекса для репозиториев..."

    declare -A repos=(
        ["fedora"]="http://mirror.yandex.ru/fedora/linux/releases/\$releasever/Everything/\$basearch/os/"
        ["fedora-updates"]="http://mirror.yandex.ru/fedora/linux/updates/\$releasever/Everything/\$basearch/"
        ["fedora-modular"]="http://mirror.yandex.ru/fedora/linux/releases/\$releasever/Modular/\$basearch/os/"
        ["fedora-updates-modular"]="http://mirror.yandex.ru/fedora/linux/updates/\$releasever/Modular/\$basearch/"
        ["rpmfusion-free"]="http://mirror.yandex.ru/fedora/rpmfusion/free/fedora/releases/\$releasever/Everything/\$basearch/os/"
        ["rpmfusion-free-updates"]="http://mirror.yandex.ru/fedora/rpmfusion/free/fedora/updates/\$releasever/Everything/\$basearch/"
        ["rpmfusion-nonfree"]="http://mirror.yandex.ru/fedora/rpmfusion/nonfree/fedora/releases/\$releasever/Everything/\$basearch/os/"
        ["rpmfusion-nonfree-updates"]="http://mirror.yandex.ru/fedora/rpmfusion/nonfree/fedora/updates/\$releasever/Everything/\$basearch/"
    )

    for repo in "${!repos[@]}"; do
        if dnf repolist --all --quiet 2>/dev/null | grep -w "^${repo}" &>/dev/null; then
            log_info "Настройка репозитория $repo..."
            dnf config-manager --set-baseurl="${repos[$repo]}" "$repo" 2>/dev/null || log_warn "Не удалось установить baseurl для $repo"
            dnf config-manager --setopt="${repo}.mirrorlist=" --save 2>/dev/null || true
            dnf config-manager --setopt="${repo}.metalink=" --save 2>/dev/null || true
        else
            log_warn "Репозиторий $repo не найден, пропускаем."
        fi
    done
}

# Функция отключения cisco openh264 в dnf
disable_cisco_openh264_dnf() {
    local repo_name="fedora-cisco-openh264"
    local repo_file="/etc/yum.repos.d/${repo_name}.repo"
    
    if [[ -f "$repo_file" ]]; then
        log_info "Отключение репозитория $repo_name..."
        dnf config-manager --set-disabled "$repo_name" 2>/dev/null || true
        # Добавляем исключение пакетов (вместо несуществующего dnf mask)
        if ! grep -q "^exclude=" "$repo_file" 2>/dev/null; then
            echo "exclude=openh264*" >> "$repo_file"
            log_info "Добавлено исключение openh264* в $repo_name"
        fi
    else
        log_info "Файл репозитория $repo_name не найден, пропускаем."
    fi
}

# Функция отключения openh264 в flatpak
disable_cisco_openh264_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        log_warn "Flatpak не установлен, пропускаем."
        return
    fi

    log_info "Настройка flatpak для блокировки openh264..."

    # Ищем remote с cisco (исправлено: без флага -d)
    local cisco_remote
    cisco_remote=$(flatpak remotes --columns=name 2>/dev/null | grep -i cisco | head -n1 | xargs) || true
    
    if [[ -n "$cisco_remote" ]]; then
        log_info "Удаление remote '$cisco_remote'..."
        flatpak remote-delete --force "$cisco_remote" 2>/dev/null || log_warn "Не удалось удалить remote"
    else
        log_info "Remote 'cisco' не найден."
    fi

    # Маскируем runtime openh264
    local mask_target="org.freedesktop.Platform.openh264"
    if flatpak mask --user "$mask_target" 2>/dev/null; then
        log_info "Замаскирован runtime $mask_target (user)."
    elif flatpak mask --system "$mask_target" 2>/dev/null; then
        log_info "Замаскирован runtime $mask_target (system)."
    else
        log_info "Runtime $mask_target не найден или уже замаскирован."
    fi

    # Дополнительно маскируем com.cisco.openh264
    flatpak mask --user com.cisco.openh264 2>/dev/null || flatpak mask --system com.cisco.openh264 2>/dev/null || true
}

# Основная логика
main() {
    log_info "Начало настройки системы..."
    add_rpmfusion
    set_yandex_mirrors
    disable_cisco_openh264_dnf
    disable_cisco_openh264_flatpak
    log_info "Очистка кэша DNF..."
    dnf clean all
    log_info "Настройка завершена успешно."
}

main
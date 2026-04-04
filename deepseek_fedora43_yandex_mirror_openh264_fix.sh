#!/usr/bin/env bash
set -euo pipefail

# Скрипт для настройки Fedora 43:
# - Добавление RPM Fusion free и non-free
# - Замена зеркал на Яндекс
# - Отключение и маскировка репозитория Cisco OpenH264 (для dnf и flatpak)

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
    log_error "Скрипт должен быть запущен с правами root (используйте sudo)."
    exit 1
fi

# Проверка версии Fedora
if ! grep -q "Fedora release 43" /etc/fedora-release 2>/dev/null; then
    log_warn "Скрипт разработан для Fedora 43, но текущая версия может отличаться."
fi

# Функция добавления RPM Fusion
add_rpmfusion() {
    local releasever
    releasever=$(rpm -E %fedora)
    local free_url="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${releasever}.noarch.rpm"
    local nonfree_url="https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${releasever}.noarch.rpm"

    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        log_info "Добавление RPM Fusion free..."
        dnf install -y --nogpgcheck "$free_url"
    else
        log_info "RPM Fusion free уже установлен."
    fi

    if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        log_info "Добавление RPM Fusion nonfree..."
        dnf install -y --nogpgcheck "$nonfree_url"
    else
        log_info "RPM Fusion nonfree уже установлен."
    fi
}

# Функция замены зеркал на Яндекс для dnf-репозиториев
set_yandex_mirrors() {
    log_info "Настройка зеркал Яндекса для основных репозиториев Fedora и RPM Fusion..."

    # Список репозиториев и соответствующих baseurl
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
        # Проверяем, существует ли репозиторий
        if dnf repolist --all 2>/dev/null | grep -q "^$repo\s"; then
            log_info "Настройка репозитория $repo..."
            # Отключаем mirrorlist и metalink, устанавливаем baseurl
            dnf config-manager --set-disable "$repo" 2>/dev/null || true
            dnf config-manager --set-enable "$repo" 2>/dev/null || true
            dnf config-manager --set-baseurl="${repos[$repo]}" "$repo" 2>/dev/null || log_warn "Не удалось установить baseurl для $repo"
            dnf config-manager --setopt="mirrorlist=" --save "$repo" 2>/dev/null || true
            dnf config-manager --setopt="metalink=" --save "$repo" 2>/dev/null || true
        else
            log_warn "Репозиторий $repo не найден, пропускаем."
        fi
    done
}

# Функция отключения и маскировки репозитория cisco openh264 в dnf
disable_cisco_openh264_dnf() {
    local repo_name="fedora-cisco-openh264"
    if dnf repolist --all 2>/dev/null | grep -q "^$repo_name\s"; then
        log_info "Отключение репозитория $repo_name..."
        dnf config-manager --set-disabled "$repo_name" 2>/dev/null || log_error "Не удалось отключить $repo_name"
        # Маскировка пакета openh264 (опционально)
        dnf mask openh264 2>/dev/null || log_info "Маскировка пакета openh264 не требуется или уже выполнена."
    else
        log_info "Репозиторий $repo_name не найден, пропускаем."
    fi
}

# Функция отключения и маскировки openh264 в flatpak
disable_cisco_openh264_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        log_warn "Flatpak не установлен, пропускаем настройку flatpak."
        return
    fi

    log_info "Настройка flatpak для блокировки openh264..."

    # 1. Отключаем глобальное разрешение на использование openh264
    flatpak config --set allow-openh264 false 2>/dev/null || log_warn "Не удалось установить allow-openh264 false"

    # 2. Ищем и удаляем remote, связанный с cisco openh264
    local cisco_remote
    cisco_remote=$(flatpak remotes -d | grep -i cisco | awk '{print $1}' | head -n1)
    if [[ -n "$cisco_remote" ]]; then
        log_info "Удаление remote '$cisco_remote'..."
        flatpak remote-delete --force "$cisco_remote" 2>/dev/null || log_error "Не удалось удалить remote $cisco_remote"
    else
        log_info "Remote с именем 'cisco' не найден."
    fi

    # 3. Маскируем runtime org.freedesktop.Platform.openh264 (если существует)
    local mask_target="org.freedesktop.Platform.openh264"
    if flatpak mask --user "$mask_target" 2>/dev/null; then
        log_info "Замаскирован runtime $mask_target для пользователя."
    else
        if flatpak mask --system "$mask_target" 2>/dev/null; then
            log_info "Замаскирован runtime $mask_target для системы."
        else
            log_info "Runtime $mask_target не найден или уже замаскирован."
        fi
    fi

    # 4. Дополнительно маскируем возможный пакет com.cisco.openh264
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
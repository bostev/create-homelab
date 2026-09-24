#!/bin/bash
set -euo pipefail

# ======================================================
# ЦВЕТА И ЛОГГИРОВАНИЕ
# ======================================================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/root/homelab_setup.log"

log() { echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[-]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }

# ======================================================
# 1. БАЗОВЫЕ ПРОВЕРКИ И ИНТЕРАКТИВНЫЙ ВВОД
# ======================================================
if [[ $EUID -ne 0 ]]; then
    error "Запустите скрипт с правами root!"
fi

clear
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}      ИНТЕРАКТИВНАЯ НАСТРОЙКА HOMELAB СЕРВЕРА         ${NC}"
echo -e "${GREEN}======================================================${NC}"

# Нейтральное имя пользователя
USERNAME="sysadmin"
echo -e "Будет настроен пользователь: ${YELLOW}$USERNAME${NC}"

# Интерактивный запрос пароля
read -s -p "Введите простой пароль для пользователя $USERNAME: " USER_PASSWORD
echo
read -s -p "Повторите пароль: " USER_PASSWORD_CONFIRM
echo

if [[ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]]; then
    error "Пароли не совпадают! Перезапустите скрипт."
fi

# Интерактивный запрос SSH-ключа
echo -e "\nВставьте ваш публичный SSH ключ (начинается с ssh-rsa, ssh-ed25519 и т.д.):"
read -r LOCAL_PUB_KEY

if [[ -z "$LOCAL_PUB_KEY" ]]; then
    error "SSH ключ не может быть пустым!"
fi

# ======================================================
# 2. ОБНОВЛЕНИЕ И БАЗОВЫЕ ПАКЕТЫ
# ======================================================
log "Обновление системы и установка базовых утилит..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y -q >/dev/null
apt-get upgrade -y -q >/dev/null

# Устанавливаем базовые утилиты и qemu-guest-agent
apt-get install -y -q curl wget htop git qemu-guest-agent >/dev/null

# Включаем агента гостевой ОС
systemctl enable --now qemu-guest-agent >/dev/null 2>&1 || true

# ======================================================
# 3. СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ И НАСТРОЙКА ПАРОЛЯ
# ======================================================
if ! id "$USERNAME" &>/dev/null; then
    log "Создание пользователя $USERNAME..."
    useradd -m -s /bin/bash "$USERNAME"
else
    log "Пользователь $USERNAME уже существует."
fi

# Установка заданного пароля
echo "$USERNAME:$USER_PASSWORD" | chpasswd
usermod -aG sudo "$USERNAME"

# Безопасный sudoers (без пароля)
log "Настройка беспарольного доступа к sudo..."
cat > /etc/sudoers.d/"$USERNAME" <<EOF
$USERNAME ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/"$USERNAME"

# ======================================================
# 4. УСТАНОВКА SSH КЛЮЧЕЙ
# ======================================================
log "Настройка авторизации по ключам..."
mkdir -p /home/"$USERNAME"/.ssh
echo "$LOCAL_PUB_KEY" > /home/"$USERNAME"/.ssh/authorized_keys
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
chmod 700 /home/"$USERNAME"/.ssh
chmod 600 /home/"$USERNAME"/.ssh/authorized_keys

# Добавляем ключ и root-пользователю
mkdir -p /root/.ssh
echo "$LOCAL_PUB_KEY" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# ======================================================
# 5. СИНХРОНИЗАЦИЯ ВРЕМЕНИ
# ======================================================
log "Синхронизация времени..."
timedatectl set-timezone UTC
timedatectl set-ntp true

# ======================================================
# 6. ФИНАЛ
# ======================================================
SERVER_IP=$(hostname -I | awk '{print $1}')

clear
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN} ✅ HOMELAB СЕРВЕР УСПЕШНО НАСТРОЕН${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "Пользователь: ${YELLOW}$USERNAME${NC}"
echo -e "SSH порт: ${YELLOW}22 (стандартный)${NC}"
echo -e "Вход по ключу: ${YELLOW}ssh $USERNAME@$SERVER_IP${NC}"
echo -e "Sudo: ${YELLOW}Без пароля (NOPASSWD)${NC}"
echo -e "======================================================"

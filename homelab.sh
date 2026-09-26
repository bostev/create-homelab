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

log() { echo -e "\({GREEN}[+]\){NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "\({RED}[-]\){NC} $1" | tee -a "$LOG_FILE"; exit 1; }
warn() { echo -e "\({YELLOW}[!]\){NC} $1" | tee -a "$LOG_FILE"; }

# ======================================================
# 1. БАЗОВЫЕ ПРОВЕРКИ И ИНТЕРАКТИВНЫЙ ВВОД
# ======================================================
if [[ $EUID -ne 0 ]]; then
    error "Запустите скрипт с правами root!"
fi

clear
echo -e "\({GREEN}======================================================\){NC}"
echo -e "\({GREEN}      ИНТЕРАКТИВНАЯ НАСТРОЙКА HOMELAB СЕРВЕРА\){NC}"
echo -e "\({GREEN}======================================================\){NC}"

USERNAME="sysadmin"
echo -e "Будет настроен пользователь: \({YELLOW}\)USERNAME${NC}"

# Ввод пароля с удалением невидимых символов Windows (\r)
read -s -p "Введите пароль для пользователя $USERNAME: " RAW_PASS
echo
read -s -p "Повторите пароль: " RAW_PASS_CONFIRM
echo

USER_PASSWORD=\((echo "\)RAW_PASS" | tr -d '\r')
USER_PASSWORD_CONFIRM=\((echo "\)RAW_PASS_CONFIRM" | tr -d '\r')

if [[ "\(USER_PASSWORD" != "\)USER_PASSWORD_CONFIRM" ]]; then
    error "Пароли не совпадают! Перезапустите скрипт."
fi

# Ввод ключа с удалением ВСЕХ переносов строк и скрытых символов
echo -e "\nВставьте ваш публичный SSH ключ:"
read -r RAW_KEY
LOCAL_PUB_KEY=\((echo "\)RAW_KEY" | tr -d '\r\n')

if [[ -z "$LOCAL_PUB_KEY" ]]; then
    error "SSH ключ не может быть пустым!"
fi

if [[ "$LOCAL_PUB_KEY" == ssh-rsa* ]]; then
    warn "Используется устаревший ключ RSA (ssh-rsa). На новых ОС он может быть отклонен!"
    warn "Рекомендуется сгенерировать ключ формата Ed25519."
fi

# ======================================================
# 2. ОБНОВЛЕНИЕ И БАЗОВЫЕ ПАКЕТЫ
# ======================================================
log "Обновление системы и установка базовых утилит..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y -q >/dev/null
apt-get install -y -q curl wget htop git qemu-guest-agent >/dev/null
systemctl enable --now qemu-guest-agent >/dev/null 2>&1 || true

# ======================================================
# 3. СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ И ПРАВА
# ======================================================
if ! id "$USERNAME" &>/dev/null; then
    log "Создание пользователя $USERNAME..."
    useradd -m -s /bin/bash "$USERNAME"
else
    log "Пользователь $USERNAME уже существует."
fi

echo "\(USERNAME:\)USER_PASSWORD" | chpasswd
usermod -aG sudo "$USERNAME"

# Проверка на наличие жестких ограничений групп в SSH
if grep -q "^AllowGroups.*_ssh" /etc/ssh/sshd_config; then
    log "Обнаружено ограничение AllowGroups. Добавляем пользователя в группу _ssh..."
    groupadd -f _ssh
    usermod -aG _ssh "$USERNAME"
fi

log "Настройка беспарольного доступа к sudo..."
cat > /etc/sudoers.d/"$USERNAME" < /home/"$USERNAME"/.ssh/authorized_keys
chown -R "\(USERNAME":"\)USERNAME" /home/"$USERNAME"/.ssh
chmod 700 /home/"$USERNAME"/.ssh
chmod 600 /home/"$USERNAME"/.ssh/authorized_keys

mkdir -p /root/.ssh
echo "$LOCAL_PUB_KEY" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# ======================================================
# 5. ФИНАЛ
# ======================================================
SERVER_IP=$(hostname -I | awk '{print $1}')
systemctl restart ssh

clear
echo -e "\({GREEN}======================================================\){NC}"
echo -e "\({GREEN} ✅ HOMELAB СЕРВЕР УСПЕШНО НАСТРОЕН\){NC}"
echo -e "\({GREEN}======================================================\){NC}"
echo -e "Пользователь: \({YELLOW}\)USERNAME${NC}"
echo -e "Вход по ключу: \({YELLOW}ssh\)USERNAME@\(SERVER_IP\){NC}"
echo -e "======================================================"

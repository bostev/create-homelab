#!/bin/bash
set -euo pipefail

# ======================================================
# ЦВЕТА И ЛОГГИРОВАНИЕ
# ======================================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN} АВТОМАТИЧЕСКОЕ СОЗДАНИЕ LXC КОНТЕЙНЕРА В PROXMOX${NC}"
echo -e "${GREEN}======================================================${NC}"

# ======================================================
# ИНТЕРАКТИВНЫЙ ВВОД ПАРАМЕТРОВ
# ======================================================
# 1. Запрос ID контейнера
read -p "Введите ID нового контейнера (например, 105): " CT_ID
if pct status "$CT_ID" &>/dev/null; then
    echo -e "${RED}[-] Ошибка: Контейнер с ID $CT_ID уже существует!${NC}"
    exit 1
fi

# 2. Запрос Hostname
read -p "Введите имя (hostname) (по умолчанию: ubuntu-server): " INPUT_HOST
HOSTNAME="${INPUT_HOST:-ubuntu-server}"

# 3. Запрос пароля
read -s -p "Введите пароль для root: " PASSWORD
echo ""

# 4. Настройка ресурсов
read -p "Количество ядер CPU (по умолчанию: 2): " INPUT_CORES
CORES="${INPUT_CORES:-2}"

read -p "Объем оперативной памяти в МБ (по умолчанию: 2048): " INPUT_MEM
MEMORY="${INPUT_MEM:-2048}"

read -p "Размер диска в ГБ (по умолчанию: 10): " INPUT_DISK
DISK="${INPUT_DISK:-10}"

# 5. Поддержка Docker
read -p "Включить поддержку Docker внутри LXC (nesting=1, keyctl=1)? (Y/n): " INPUT_DOCKER
DOCKER_OPT=""
if [[ "$INPUT_DOCKER" != "n" && "$INPUT_DOCKER" != "N" ]]; then
    DOCKER_OPT="--features nesting=1,keyctl=1"
    echo -e "-> ${YELLOW}Поддержка Docker включена.${NC}"
fi

# ======================================================
# ВНУТРЕННИЕ ПАРАМЕТРЫ (можно изменить под свою среду)
# ======================================================
STORAGE="nvme_fast"           # Хранилище для диска контейнера
TEMPLATE_STORAGE="local"      # Хранилище для образов/шаблонов
NETWORK="name=eth0,bridge=vmbr_mgmt,ip=dhcp" # Сетевой интерфейс по умолчанию

# Автоматический поиск самого свежего шаблона Ubuntu 22.04 в репозитории Proxmox
echo -e "\n${GREEN}[+] Обновление списка шаблонов Proxmox...${NC}"
pveam update >/dev/null

TEMPLATE_NAME=$(pveam available -section system | grep 'ubuntu-22.04-standard' | awk '{print $2}' | head -n 1)

if [[ -z "$TEMPLATE_NAME" ]]; then
    echo -e "${RED}[-] Ошибка: Не удалось найти шаблон Ubuntu 22.04 в репозитории.${NC}"
    exit 1
fi

TEMPLATE_VOL="${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE_NAME}"

# Проверка и скачивание шаблона, если его нет локально
if ! pvesm list "$TEMPLATE_STORAGE" | grep -q "$TEMPLATE_NAME"; then
    echo -e "${YELLOW}[+] Шаблон $TEMPLATE_NAME не найден локально. Скачивание...${NC}"
    pveam download "$TEMPLATE_STORAGE" "$TEMPLATE_NAME" >/dev/null
else
    echo -e "${GREEN}[+] Шаблон $TEMPLATE_NAME уже присутствует локально.${NC}"
fi

# ======================================================
# СОЗДАНИЕ И ЗАПУСК КОНТЕЙНЕРА
# ======================================================
echo -e "${YELLOW}[+] Создание непривилегированного контейнера $CT_ID ($HOSTNAME)...${NC}"
pct create "$CT_ID" "$TEMPLATE_VOL" \
    --hostname "$HOSTNAME" \
    --password "$PASSWORD" \
    --net0 "$NETWORK" \
    --storage "$STORAGE" \
    --rootfs "${STORAGE}:${DISK}" \
    --cores "$CORES" \
    --memory "$MEMORY" \
    --unprivileged 1 \
    $DOCKER_OPT >/dev/null

echo -e "${YELLOW}[+] Запуск контейнера...${NC}"
pct start "$CT_ID"

# Даем контейнеру пару секунд на получение IP-адреса
sleep 3
IP_ADDRESS=$(pct exec "$CT_ID" -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "IP_НЕ_ПОЛУЧЕН")

echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN} ✅ КОНТЕЙНЕР УСПЕШНО СОЗДАН И ЗАПУЩЕН${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "ID: ${YELLOW}$CT_ID${NC}"
echo -e "Имя: ${YELLOW}$HOSTNAME${NC}"
echo -e "IP-адрес: ${YELLOW}$IP_ADDRESS${NC}"
echo ""
echo -e "Чтобы войти в контейнер прямо сейчас, выполните:"
echo -e "${YELLOW}pct enter $CT_ID${NC}"
echo -e "======================================================"

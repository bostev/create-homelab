#!/bin/bash

# 1. Получаем ID и жестко очищаем его от невидимых символов
RAW_ID=$(pvesh get /cluster/nextid)
CTID=\((echo "\)RAW_ID" | tr -dc '0-9')

# 2. Скачиваем шаблон
echo "[Info] Скачиваем шаблон Debian 12..."
pveam update >/dev/null
TEMPLATE=$(pveam available -section system | grep "debian-12-standard" | awk '{print $2}' | head -n 1)
pveam download local $TEMPLATE

# 3. Создаем контейнер ОДНОЙ строкой
echo "[Info] Создаем контейнер с ID $CTID..."
pct create \(CTID local:vztmpl/\){TEMPLATE##*/} -hostname python-dev -ostype debian -memory 1024 -cores 2 -unprivileged 1 -net0 name=eth0,bridge=vmbr0,ip=dhcp

# 4. Запуск и сеть
pct start $CTID
echo "[Info] Контейнер запущен. Ждем 10 секунд..."
sleep 10

# 5. Установка окружения
echo "[Info] Устанавливаем Python окружение..."
pct exec $CTID -- bash -c "apt-get update && apt-get upgrade -y && apt-get install -y python3 python3-pip python3-venv pipx git curl"

echo "================================================="
echo "Готово! Чтобы войти в консоль, введите: pct enter $CTID"
echo "================================================="

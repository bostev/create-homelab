#!/bin/bash
# 1. Находим свободный ID для нового контейнера
CTID=$(pvesh get /cluster/nextid)

# 2. Обновляем список шаблонов и скачиваем актуальный Debian 12
echo "[Info] Скачиваем шаблон Debian 12..."
pveam update >/dev/null
TEMPLATE=$(pveam available -section system | grep "debian-12-standard" | awk '{print $2}' | head -n 1)
pveam download local $TEMPLATE

# 3. Создаем базовый непривилегированный контейнер
echo "[Info] Создаем контейнер с ID $CTID..."
pct create \(CTID local:vztmpl/\){TEMPLATE##*/} \
  -hostname python-dev \
  -ostype debian \
  -memory 1024 \
  -cores 2 \
  -unprivileged 1 \
  -net0 name=eth0,bridge=vmbr0,ip=dhcp

# 4. Запускаем контейнер и ждем получения IP-адреса
pct start $CTID
echo "[Info] Контейнер запущен. Ждем 10 секунд для инициализации сети..."
sleep 10

# 5. Устанавливаем Python, pip, pipx и git внутри LXC
echo "[Info] Устанавливаем Python окружение..."
pct exec $CTID -- bash -c "apt-get update && apt-get upgrade -y && apt-get install -y python3 python3-pip python3-venv pipx git curl"

echo "================================================="
echo "Готово! Python-окружение установлено в LXC $CTID"
echo "Чтобы войти в консоль, введите команду:"
echo "pct enter $CTID"
echo "================================================="

#!/bin/bash

APP_DIR="app"

echo "==========================================="
echo " Настройка контейнера Debian + Python"
echo "==========================================="

mkdir -p "$APP_DIR"
cd "$APP_DIR" || exit

# 1. Создаем Dockerfile на базе Debian
cat << 'EOF' > Dockerfile
FROM debian:bookworm-slim

# Отключаем интерактивные запросы при установке
ENV DEBIAN_FRONTEND=noninteractive

# Обновляем систему и устанавливаем Python, pip и venv
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Создаем и активируем виртуальное окружение
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Копируем список зависимостей и устанавливаем их
COPY requirements.txt* ./
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Копируем скрипты и остальные файлы проекта
COPY . .

# Команда запуска (можно изменить под свой скрипт)
CMD ["python3", "main.py"]
EOF

# 2. Создаем шаблон requirements.txt
if [ ! -f requirements.txt ]; then
cat << 'EOF' > requirements.txt
# Добавь сюда нужные библиотеки для твоего скрипта
# requests
# bs4
EOF
fi

# 3. Создаем тестовый Python-скрипт
if [ ! -f main.py ]; then
cat << 'EOF' > main.py
import sys
print("=======================================")
print(f"Привет! Контейнер Debian успешно запущен.")
print(f"Версия Python: {sys.version}")
print("=======================================")
EOF
fi

# 4. Создаем docker-compose.yml
cat << 'EOF' > docker-compose.yml
version: '3.8'
services:
  python_app:
    build: .
    container_name: debian_python_script
    restart: unless-stopped
    volumes:
      - .:/app
EOF

echo "[+] Файлы успешно созданы в папке $APP_DIR."
echo "[*] Запускаем сборку и развертывание контейнера..."

# Проверяем наличие Docker и запускаем
if command -v docker &> /dev/null; then
    if docker compose version &> /dev/null; then
        docker compose up -d --build
    elif command -v docker-compose &> /dev/null; then
        docker-compose up -d --build
    else
        echo "[-] Утилита Docker Compose не найдена."
        exit 1
    fi
    echo "[+] Контейнер развернут и работает в фоновом режиме!"
    echo "[*] Чтобы посмотреть логи, выполни: cd $APP_DIR && docker compose logs -f"
else
    echo "[-] Docker не установлен в системе."
    echo "[-] Установи Docker, перейди в папку $APP_DIR и выполни 'docker compose up -d --build'."
fi

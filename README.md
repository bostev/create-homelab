🛠️ create-homelabНабор легковесных Bash-скриптов для автоматизации развертывания домашней лаборатории, базовой защиты Linux/VPS серверов и быстрого создания LXC-контейнеров с Python-окружением в Proxmox VE.⚡ Быстрый запуск напрямую из GitHubСкрипты можно выполнять в одну строку без клонирования всего репозитория.1. Настройка домашней лаборатории (homelab.sh)Установка системных утилит, Docker Engine и Compose:# Через curl:
curl -fsSL https://raw.githubusercontent.com/bostev/create-homelab/main/homelab.sh | sudo bash

# Через wget:
wget -qO- https://raw.githubusercontent.com/bostev/create-homelab/main/homelab.sh | sudo bash
2. Базовый харденинг сервера (secure-vps-minimal.sh)Настройка брандмауэра UFW, защита от брутфорса с Fail2ban и ограничение доступа по SSH:# Через curl:
curl -fsSL https://raw.githubusercontent.com/bostev/create-homelab/main/secure-vps-minimal.sh | sudo bash

# Через wget:
wget -qO- https://raw.githubusercontent.com/bostev/create-homelab/main/secure-vps-minimal.sh | sudo bash
3. Создание Python LXC-контейнера (create-python-lxc.sh)Развертывание изолированного контейнера с Python 3, pip и venv (запускается в шелле Proxmox VE):# Через curl:
curl -fsSL https://raw.githubusercontent.com/bostev/create-homelab/main/create-python-lxc.sh | bash

# Через wget:
wget -qO- https://raw.githubusercontent.com/bostev/create-homelab/main/create-python-lxc.sh | bash
📌 Быстрый переход к файламСкриптНазначениеИсходный кодПрямая ссылка (Raw)homelab.shБазовая среда хоумлаба, Docker, базовый софтОткрыть кодRaw-файлsecure-vps-minimal.shМинимальная защита и харденинг VPS/LinuxОткрыть кодRaw-файлcreate-python-lxc.shАвтосоздание Proxmox LXC-контейнера под PythonОткрыть кодRaw-файл🚀 Описание модулейhomelab.shОсновной скрипт развертывания хоумлаб-окружения:Синхронизирует и обновляет системные репозитории (apt update && apt upgrade).Устанавливает базовый набор утилит администратора (curl, git, htop, tmux, jq и др.).Инсталлирует Docker Engine и Docker Compose из официальных репозиториев.Подготавливает структуру рабочих каталогов для сервисов.secure-vps-minimal.shБыстрое приведение нового сервера к базовому стандарту безопасности:Включает и конфигурирует ufw (запрещает все входящие подключения, кроме разрешенных).Разворачивает и настраивает fail2ban для фильтрации попыток перебора паролей SSH.Отключает вход по паролю (рекомендуется использовать SSH-ключи) и запрещает вход root по паролю.create-python-lxc.shСкрипт автоматизации для хоста Proxmox VE:Загружает базовый образ контейнера (Debian / Ubuntu / Alpine).Создает непривилегированный LXC-контейнер с предустановленными квотами CPU, RAM и диска.Устанавливает python3, python3-pip, python3-venv и подготавливает изолированное виртуальное окружение для микросервисов и ботов.📥 Альтернативный способ: локальный запускЕсли вам нужно предварительно отредактировать параметры конфигурации:git clone https://github.com/bostev/create-homelab.git
cd create-homelab
chmod +x *.sh

# Запуск выбранного скрипта:
sudo ./homelab.sh
# или
sudo ./secure-vps-minimal.sh
# или (в консоли Proxmox)
./create-python-lxc.sh
📋 Системные требованияОС: Debian 11/12 или Ubuntu 20.04/22.04/24.04 LTS.Proxmox: VE 7.x или 8.x (только для create-python-lxc.sh).Права: Пользователь с правами sudo или root.⚠️ Предостережение (Disclaimer)Перед запуском скриптов через пайплайн curl ... | sudo bash всегда рекомендуется предварительно просмотреть исходный код на предмет совместимости с вашей конфигурацией сети и портами SSH.

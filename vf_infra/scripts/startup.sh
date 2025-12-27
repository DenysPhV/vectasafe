#!/bin/bash
set -e

# Встановлення залежностей
apt-get update
apt-get install -y python3-pip git wget docker.io

# Встановлення Google Cloud Ops Agent (для логів та моніторингу RAM)
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# --- Отримання пароля з Secret Manager ---
# Ми використовуємо gcloud, який вже є на VM, і права service account
DB_PASSWORD=$(gcloud secrets versions access latest --secret="${db_secret_id}")

# Встановлення Cloud SQL Auth Proxy
wget https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64 -O /usr/local/bin/cloud-sql-proxy
chmod +x /usr/local/bin/cloud-sql-proxy

# Налаштування сервісу Cloud SQL Proxy
# Він слухатиме localhost:5432 і тунелюватиме трафік в Cloud SQL
cat <<EOF > /etc/systemd/system/cloud-sql-proxy.service
[Unit]
Description=Google Cloud SQL Auth Proxy
After=network.target

[Service]
User=root
Type=simple
# ${db_connection_name} підставиться Terraform-ом
ExecStart=/usr/local/bin/cloud-sql-proxy ${db_connection_name} --port 5432
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cloud-sql-proxy
systemctl start cloud-sql-proxy

# Налаштування застосунку VectaSafe
git clone https://github.com/DenysPhV/vectasafe.git /opt/vectasafe
cd /opt/vectasafe
docker build -t vectasafe-backend:latest .

# Створення сервісу VectaSafe (Docker Run)
# Додаємо змінні оточення для підключення до БД через localhost
cat <<EOF > /etc/systemd/system/vectasafe.service
[Unit]
Description=VectaSafe API (Docker)
After=docker.service cloud-sql-proxy.service
Requires=docker.service cloud-sql-proxy.service

[Service]
User=root
WorkingDirectory=/opt/vectasafe
Restart=always

# Запускаємо контейнер
# --network="host": щоб контейнер бачив Cloud SQL Proxy на localhost:5432
# --rm: видалити контейнер після зупинки (щоб не накопичувались старі)
# -e ...: передаємо змінні оточення всередину контейнера
ExecStart=/usr/bin/docker run --rm --network="host" --name vectasafe_app \
  -e DB_HOST=127.0.0.1 \
  -e DB_PORT=5432 \
  -e DB_USER=vsafe_admin \
  -e DB_NAME=vectasafe \
  -e DB_PASS=$DB_PASSWORD \
  vectasafe-backend:latest
      
# Зупинка контейнера при зупинці сервісу
ExecStop=/usr/bin/docker stop vectasafe_app

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vectasafe.service
systemctl start vectasafe.service
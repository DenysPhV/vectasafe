#!/bin/bash
set -e

echo ">>> [VectaSafe] STARTING INFRASTRUCTURE PROVISIONING..."

# ==============================================================================
# 1. SYSTEM SETUP & DOCKER INSTALLATION (Official Script)
# ==============================================================================
# Видаляємо старі версії, якщо є, щоб уникнути конфліктів
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Встановлюємо Docker через офіційний скрипт (включає Docker Compose V2 plugin)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

echo ">>> [VectaSafe] Docker installed successfully."

# Встановлюємо unzip
apt-get update && apt-get install -y unzip

# ==============================================================================
# 2. VARIABLE INJECTION (FROM TERRAFORM)
# ==============================================================================
# Terraform замінить ці змінні завдяки функції templatefile()
BUCKET="${tpl_bucket_name}"
ARCHIVE="${tpl_archive_name}"
DB_HOST="${tpl_db_host}"
DB_PASS="${tpl_db_pass}"

echo ">>> [VectaSafe] Configuration: Bucket=$BUCKET, Archive=$ARCHIVE, DB_Host=$DB_HOST"

# ==============================================================================
# 3. CODE DEPLOYMENT
# ==============================================================================
WORK_DIR="/app/backend"
mkdir -p $WORK_DIR
cd $WORK_DIR

# Завантажуємо код через gsutil (вбудований в image GCP)
echo ">>> [VectaSafe] Downloading application code..."
gsutil cp "gs://$BUCKET/$ARCHIVE" app.zip
unzip -o app.zip
rm app.zip

# ==============================================================================
# 4. CONFIGURATION GENERATION (.env)
# ==============================================================================
echo ">>> [VectaSafe] Generating secure environment variables..."
cat <<EOF > .env
POSTGRES_USER=vecta_user
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_HOST=$DB_HOST
POSTGRES_DB=vectasafe
POSTGRES_PORT=5432
# Генеруємо криптографічно стійкий ключ
VECTA_SECRET_KEY=$(openssl rand -hex 32)
# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
# Qdrant Configuration
QDRANT_HOST=qdrant
QDRANT_PORT=6333
EOF

# ==============================================================================
# 5. SERVICE STARTUP
# ==============================================================================
echo ">>> [VectaSafe] Starting services via Docker Compose..."

# Використовуємо нову команду 'docker compose' (V2), а не 'docker-compose' (V1)
if [ -f "docker-compose.yml" ]; then
    docker compose up -d --build
else
    echo "!!! ERROR: docker-compose.yml not found in $WORK_DIR"
    exit 1
fi

echo ">>> [VectaSafe] DEPLOYMENT COMPLETE. Services are running on port 8080."
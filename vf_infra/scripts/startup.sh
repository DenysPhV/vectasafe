#!/bin/bash
set -e

echo ">>> [VectaSafe] STARTING GIT DEPLOYMENT..."

# 1. INSTALL DOCKER & GIT
# Чистка старих версій
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Встановлення Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Встановлення Git
apt-get update && apt-get install -y git

echo ">>> [VectaSafe] Environment ready."

# 2. LOAD VARIABLES
REPO_URL="${tpl_repo_url}"
BRANCH="${tpl_branch_name}"
DB_HOST="${tpl_db_host}"
DB_PASS="${tpl_db_pass}"

echo ">>> [VectaSafe] Cloning from $REPO_URL (branch: $BRANCH)..."

# 3. CLONE REPOSITORY
# Видаляємо папку, якщо вона є (для чистоти експерименту при перезапусках)
rm -rf /app/vectasafe

# Клонуємо весь репозиторій
mkdir -p /app
cd /app
git clone -b $BRANCH $REPO_URL vectasafe

# Переходимо в папку backend (важливо! у вашому репо вона всередині)
cd /app/vectasafe/backend

# 4. GENERATE CONFIGURATION (.env)
echo ">>> [VectaSafe] Generating .env..."
cat <<EOF > .env
POSTGRES_USER=vecta_user
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_HOST=$DB_HOST
POSTGRES_DB=vectasafe
POSTGRES_PORT=5432
VECTA_SECRET_KEY=$(openssl rand -hex 32)
# Redis & Qdrant (hostnames from docker-compose services)
REDIS_HOST=redis
REDIS_PORT=6379
QDRANT_HOST=qdrant
QDRANT_PORT=6333
EOF

# 5. START DOCKER
echo ">>> [VectaSafe] Starting services..."

# Використовуємо нову команду 'docker compose' (V2)
docker compose down --remove-orphans || true # На всяк випадок
docker compose up -d --build

echo ">>> [VectaSafe] DEPLOYMENT COMPLETE via GIT!"
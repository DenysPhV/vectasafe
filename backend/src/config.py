# src/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App
    APP_NAME: str = "Vecta Safe MVP"
    SECRET_KEY: str = "change_me_in_prod_please" # Для JWT токенів

    # Database (PostgreSQL)
    DB_URL: str = "postgresql+asyncpg://user:pass@db:5432/vectasafe"

    # Queue (Redis)
    REDIS_HOST: str = "redis"
    REDIS_PORT: int = 6379

    # Vector DB (Qdrant)
    QDRANT_HOST: str = "qdrant"
    QDRANT_PORT: int = 6333
    QDRANT_COLLECTION: str = "documents"

    # Storage (S3 / MinIO)
    S3_ENDPOINT_URL: str = "http://minio:9000" # Або AWS S3 URL
    S3_ACCESS_KEY: str = "minioadmin"
    S3_SECRET_KEY: str = "minioadmin"
    S3_BUCKET_NAME: str = "vecta-encrypted-bucket"
    S3_REGION: str = "us-east-1"

    class Config:
        env_file = ".env"

settings = Settings()
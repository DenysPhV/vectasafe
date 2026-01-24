# src/config.py
from pydantic_settings import BaseSettings
from pydantic import Field

class Settings(BaseSettings):
    # App
    APP_NAME: str = "Vecta Safe MVP"
    SECRET_KEY: str = Field(..., alias="VECTA_SECRET_KEY")

    # Database (PostgreSQL)
    DB_USER: str = Field(..., alias="POSTGRES_USER")
    DB_PASSWORD: str = Field(..., alias="POSTGRES_PASSWORD")
    DB_HOST: str = Field("db", alias="POSTGRES_HOST")
    DB_NAME: str = Field("vectasafe", alias="POSTGRES_DB")

    @property
    def DB_URL(self) -> str:
        return f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:5432/{self.DB_NAME}"

    class Config:
        env_file = ".env" 

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
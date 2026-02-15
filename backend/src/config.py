# src/config.py
from pydantic_settings import BaseSettings
from pydantic import Field

class Settings(BaseSettings):
    # App
    APP_NAME: str = "Vecta Safe MVP"
    VECTA_SECRET_KEY: str = Field(..., alias="VECTA_SECRET_KEY")

    # Database (PostgreSQL)
    DB_USER: str = Field(..., alias="POSTGRES_USER")
    DB_PASSWORD: str = Field(..., alias="POSTGRES_PASSWORD")
    DB_HOST: str = Field("db", alias="POSTGRES_HOST")
    DB_PORT: int = Field(5432, alias="POSTGRES_PORT")
    DB_NAME: str = Field("vectasafe", alias="POSTGRES_DB")

    @property
    def DB_URL(self) -> str:
        return f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    class Config:
        env_file = ".env"
        extra = "ignore" 

    # Queue (Redis)
    REDIS_HOST: str = Field("redis", alias="REDIS_HOST")
    REDIS_PORT: int = Field(6379, alias="REDIS_PORT")

    # Vector DB (Qdrant)
    QDRANT_HOST: str = Field("qdrant", alias="QDRANT_HOST")
    QDRANT_PORT: int = Field(6333, alias="QDRANT_PORT")
    QDRANT_COLLECTION: str = "documents"

    # Storage (S3 / MinIO)
    S3_ENDPOINT_URL: str = "http://minio:9000" # Або AWS S3 URL
    S3_ACCESS_KEY: str = "minioadmin"
    S3_SECRET_KEY: str = "minioadmin"
    S3_BUCKET_NAME: str = "vecta-encrypted-bucket"
    S3_REGION: str = "us-east-1"

settings = Settings()

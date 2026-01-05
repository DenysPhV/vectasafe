import os
import logging
from datetime import datetime
from fastapi import FastAPI, UploadFile, File, HTTPException, Depends
from google.cloud import storage
from sqlalchemy import create_engine, Column, Integer, String, DateTime, text
from sqlalchemy.orm import sessionmaker, declarative_base, Session

# --- Конфігурація ---
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "password")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "vectasafe")
BUCKET_NAME = os.getenv("BUCKET_NAME")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:5432/{DB_NAME}"

# --- Логування ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- База Даних ---
Base = declarative_base()

class FileRecord(Base):
    __tablename__ = "files"
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String, nullable=False)
    gcs_path = Column(String, nullable=False)
    status = Column(String, default="uploaded")  # uploaded, processing, done
    upload_date = Column(DateTime, default=datetime.utcnow)

# Підключення до БД
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Створення таблиць (проста міграція при старті)
try:
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created successfully.")
except Exception as e:
    logger.error(f"Error creating tables: {e}")

# --- Google Cloud Storage ---
storage_client = storage.Client()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- FastAPI App ---
app = FastAPI(title="VectaSafe API")

@app.get("/")
def read_root():
    return {"message": "VectaSafe API is running", "bucket": BUCKET_NAME}

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.post("/upload")
async def upload_file(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """
    1. Отримує файл.
    2. Завантажує його в GCS Bucket.
    3. Створює запис в PostgreSQL.
    """
    if not BUCKET_NAME:
        raise HTTPException(status_code=500, detail="Bucket name not configured")

    try:
        # 1. Завантаження в GCS
        bucket = storage_client.bucket(BUCKET_NAME)
        # Генеруємо унікальне ім'я (можна додати UUID, але поки просто оригінальне)
        blob = bucket.blob(file.filename)
        
        # Читаємо файл і вантажимо (для великих файлів краще stream, але для початку так)
        blob.upload_from_file(file.file)
        
        gcs_uri = f"gs://{BUCKET_NAME}/{file.filename}"
        logger.info(f"File uploaded to {gcs_uri}")

        # 2. Запис в БД
        db_file = FileRecord(filename=file.filename, gcs_path=gcs_uri)
        db.add(db_file)
        db.commit()
        db.refresh(db_file)

        return {
            "id": db_file.id,
            "filename": db_file.filename,
            "gcs_path": db_file.gcs_path,
            "status": "success"
        }

    except Exception as e:
        logger.error(f"Upload failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
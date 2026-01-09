import os
import uvicorn
import logging
import asyncio

from datetime import datetime, timezone
from functools import partial
from concurrent.futures import ThreadPoolExecutor

from google.cloud import storage

from fastapi import FastAPI, UploadFile, File, HTTPException, Depends
from sqlalchemy import create_engine, Column, Integer, String, DateTime, text
from sqlalchemy.orm import sessionmaker, declarative_base, Session

# --- Конфігурація ---
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
BUCKET_NAME = os.getenv("BUCKET_NAME")
PORT = os.getenv("PORT")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:5432/{DB_NAME}"

# --- Логування ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- База Даних ---
Base = declarative_base()

# Допоміжна функція для отримання поточного часу в UTC
def get_utc_now():
    return datetime.now(timezone.utc)

class FileRecord(Base):
    __tablename__ = "files"
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String, nullable=False)
    gcs_path = Column(String, nullable=False)
    status = Column(String, default="uploaded")  # uploaded, processing, done
    upload_date = Column(DateTime(timezone=True), default=get_utc_now)

# Підключення до БД
engine = create_engine(
    DATABASE_URL,
    pool_size=20,          # Оптимізація: пул з'єднань
    max_overflow=10,       # Додаткові з'єднання при піках
    pool_pre_ping=True     # Перевірка з'єднання перед використанням (fault tolerance)
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# У ПРОДАКШЕНІ ЦЕ ПРИБРАТИ І ВИКОРИСТОВУВАТИ ALEMBIC
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

# --- Utility: Non-blocking GCS Upload ---
# Створюємо пул потоків для блокуючих операцій I/O
io_executor = ThreadPoolExecutor(max_workers=10)

def upload_to_gcs_sync(file_obj, filename: str, bucket_name: str) -> str:
    """Синхронна функція завантаження, яка буде запущена в окремому потоці."""
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(filename)
    # Rewind file to start just in case
    file_obj.seek(0)
    blob.upload_from_file(file_obj)
    return f"gs://{bucket_name}/{filename}"

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
        # 1. Non-blocking upload to GCS
        # Ми запускаємо синхронну функцію в ThreadPoolExecutor, щоб не блокувати Event Loop
        loop = asyncio.get_running_loop()
        gcs_uri = await loop.run_in_executor(
            io_executor, 
            partial(upload_to_gcs_sync, file.file, file.filename, BUCKET_NAME)
        )
        
        logger.info(f"File uploaded asynchronously to {gcs_uri}")

        # 2. Запис в БД (SQLAlchemy в даному прикладі синхронна, але виконується швидко.
        # Для ідеального рішення варто перейти на async SQLAlchemy)
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
        raise HTTPException(status_code=500, detail="Internal Server Error")
    
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=PORT)
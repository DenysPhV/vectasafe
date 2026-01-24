# src/main.py
from fastapi import FastAPI, UploadFile, File, Form, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from arq import create_pool
from arq.connections import RedisSettings

from database import get_db, init_db
from models import Document, User
import uuid

app = FastAPI(title="Vecta Safe MVP")

# Redis Pool для черги
async def get_redis():
    return await create_pool(RedisSettings(host='redis', port=6379))

@app.on_event("startup")
async def startup():
    await init_db() # Створення таблиць

@app.post("/upload/complete")
async def complete_upload(
    s3_path: str = Form(...),
    doc_key_enc_hex: str = Form(...), # Зашифрований клієнтом ключ
    iv_hex: str = Form(...),
    # В реальності session_key береться з Auth Middleware (JWT)
    temp_session_key: str = Form(...), 
    db: AsyncSession = Depends(get_db),
    redis = Depends(get_redis)
):
    """
    Клієнт вже завантажив файл в S3 і шифрував його.
    Ми зберігаємо метадані і запускаємо воркер.
    """
    # 1. Зберігаємо метадані [cite: 421]
    new_doc = Document(
        id=uuid.uuid4(),
        owner_id=uuid.UUID("..."), # Hardcoded for MVP or from Token
        s3_path=s3_path,
        doc_key_enc=bytes.fromhex(doc_key_enc_hex),
        aes_iv=bytes.fromhex(iv_hex),
        status="PROCESSING"
    )
    db.add(new_doc)
    await db.commit()
    
    # 2. Ставимо завдання в чергу Worker-у [cite: 27, 422]
    # Передаємо ID і тимчасовий ключ сесії для розшифрування
    await redis.enqueue_job(
        "process_document_task", 
        str(new_doc.id), 
        temp_session_key
    )
    
    return {"status": "queued", "doc_id": str(new_doc.id)}
import uuid
import uvicorn
import os

from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from arq import create_pool
from arq.connections import RedisSettings

try:
    from database import get_db, init_db
    from models import Document
    from schemas import UploadCompleteRequest
except ImportError:
    # Fallback для запуску з кореня
    from src.database import get_db, init_db
    from src.models import Document
    from src.schemas import UploadCompleteRequest

app = FastAPI(title="Vecta Safe MVP")

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))

async def get_redis():
    return await create_pool(RedisSettings(host=REDIS_HOST, port=REDIS_PORT))

@app.on_event("startup")
async def startup():
    print(">>> Starting up: Initializing DB...")
    await init_db()
    print(">>> DB Initialized.")

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "backend-api"}

@app.post("/upload/complete")
async def complete_upload(
    payload: UploadCompleteRequest,
    db: AsyncSession = Depends(get_db),
    redis = Depends(get_redis)
):
    """
    Зберігає метадані та ставить задачу в чергу.
    """
    try:
        new_doc = Document(
            id=uuid6.uuid7(),
            owner_id=uuid.uuid4(), # TODO: Замінити на реального юзера з токена
            s3_path=payload.s3_path, 
            doc_key_enc=bytes.fromhex(payload.doc_key_enc_hex),
            aes_iv=bytes.fromhex(payload.iv_hex),
            status="PROCESSING"
        )
        
        db.add(new_doc)
        await db.commit()
        
        await redis.enqueue_job(
            "process_document_task", 
            str(new_doc.id), 
            payload.encrypted_session_payload 
        )
        
        return {"status": "queued", "doc_id": str(new_doc.id)}

    except Exception as e:
        print(f"ERROR in complete_upload: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
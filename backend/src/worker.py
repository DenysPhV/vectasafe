# src/worker.py
import asyncio
import gc
from arq import Worker
from sqlalchemy.future import select
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct, VectorParams, Distance

# Імпорти з наших модулів
from database import async_session_factory
from models import Document, User
from services.crypto import CryptoEngine
# from services.storage import download_blob (Заглушка)
from services.ml import embed_text # (Потрібно реалізувати або використовувати mock)

# Налаштування Qdrant [cite: 36]
qdrant = QdrantClient(host="qdrant", port=6333)

async def process_document_task(ctx, doc_id_str: str, session_key_hex: str):
    """
    Основна функція RAG Pipeline.
    """
    print(f"🚀 Starting secure processing for {doc_id_str}")
    
    async with async_session_factory() as db:
        # 1. Отримуємо метадані
        result = await db.execute(select(Document).where(Document.id == doc_id_str))
        doc = result.scalar_one_or_none()
        
        user_res = await db.execute(select(User).where(User.id == doc.owner_id))
        user = user_res.scalar_one_or_none()
        
        if not doc or not user:
            return "Error: Doc or User not found"

        plaintext = None
        doc_key = None
        
        try:
            # 2. Завантаження зашифрованого блоба (Mock S3)
            # encrypted_blob = await download_blob(doc.s3_path)
            encrypted_blob = b"encrypted_bytes_simulation" 

            # 3. CRITICAL: Розшифрування в пам'яті [cite: 30]
            session_key = bytes.fromhex(session_key_hex)
            
            # "Магія" ключів
            doc_key = CryptoEngine.unwrap_keys(
                session_key, 
                user.encrypted_private_key, 
                doc.doc_key_enc
            )
            
            # Отримання чистого тексту
            plaintext = CryptoEngine.decrypt_content(
                encrypted_blob, doc_key, doc.aes_iv
            )
            
            # 4. Векторизація (OCR + Embeddings) [cite: 34]
            # text_chunks = split_text(plaintext.decode())
            # vectors = model.encode(text_chunks)
            
            # Емуляція векторів
            fake_vector = [0.1] * 384 

            # 5. Запис в Qdrant [cite: 36]
            qdrant.upsert(
                collection_name="documents",
                points=[
                    PointStruct(
                        id=str(doc.id), # або uuid
                        vector=fake_vector,
                        payload={"doc_id": str(doc.id), "text": "Decrypted snippet..."}
                    )
                ]
            )
            
            # 6. Оновлення статусу
            doc.status = "READY"
            await db.commit()
            print("✅ Document processed and secure connection closed.")

        except Exception as e:
            print(f"❌ Error processing: {e}")
            doc.status = "FAILED"
            await db.commit()
            
        finally:
            # 7. Зачистка пам'яті [cite: 35]
            del plaintext
            del doc_key
            del session_key
            gc.collect()

# Налаштування ARQ (Redis)
class WorkerSettings:
    functions = [process_document_task]
    redis_settings = {"host": "redis", "port": 6379}
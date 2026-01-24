# src/schemas.py
from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import Optional

# --- Shared Properties ---
class DocumentBase(BaseModel):
    s3_path: str

# --- Вхідні дані для API (POST /upload/complete) ---
class DocumentUploadComplete(DocumentBase):
    doc_key_enc_hex: str  # Зашифрований клієнтом ключ (hex string)
    iv_hex: str           # Вектор ініціалізації (hex string)
    # Тимчасовий ключ сесії (тільки для MVP, в проді береться з JWT)
    temp_session_key_hex: str 

# --- Вихідні дані (Response) ---
class DocumentResponse(DocumentBase):
    id: UUID4
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True # Дозволяє читати з ORM об'єктів

# --- Для RAG пошуку (Chat) ---
class SearchQuery(BaseModel):
    query_text: str
    limit: int = 5

class SearchResponse(BaseModel):
    doc_id: str
    score: float
    text_snippet: str
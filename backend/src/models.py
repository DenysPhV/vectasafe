# src/models.py
from sqlalchemy import Column, String, Boolean, ForeignKey, LargeBinary, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base
import uuid

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=False)
    # Зберігаємо зашифрований приватний ключ (AES-KW) [cite: 9]
    encrypted_private_key = Column(LargeBinary, nullable=False)
    public_key = Column(LargeBinary, nullable=False)  # X25519 public key

class Document(Base):
    __tablename__ = "documents"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    s3_path = Column(String, unique=True, nullable=False)
    
    # Метадані шифрування (Server never sees plaintext keys) [cite: 19]
    doc_key_enc = Column(LargeBinary, nullable=False) # Зашифрований ключ файлу
    aes_iv = Column(LargeBinary, nullable=False)
    
    status = Column(String, default="UPLOADED") # UPLOADED -> PROCESSING -> READY
    created_at = Column(DateTime(timezone=True), server_default=func.now())
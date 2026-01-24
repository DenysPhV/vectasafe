# src/services/crypto.py
from cryptography.hazmat.primitives.keywrap import aes_key_unwrap
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

class CryptoEngine:
    @staticmethod
    def unwrap_keys(master_key: bytes, encrypted_priv_key: bytes, wrapped_doc_key: bytes) -> bytes:
        """
        Відновлює ключ документа.
        1. User Master Key -> розгортає User Private Key (AES-KW)
        2. User Private Key -> розгортає Document Key
        """
        try:
            # Крок 1: Розгортаємо приватний ключ [cite: 9, 331]
            user_priv_key = aes_key_unwrap(master_key, encrypted_priv_key)
            
            # Крок 2: Розгортаємо ключ файлу (спрощено, для X25519 потрібна інша ліба)
            # В реальності тут асиметричне розшифрування. Для MVP емулюємо:
            doc_key = aes_key_unwrap(user_priv_key[:32], wrapped_doc_key)
            
            return doc_key
        except Exception as e:
            raise ValueError(f"Key unwrapping failed: {e}")

    @staticmethod
    def decrypt_content(ciphertext: bytes, key: bytes, iv: bytes) -> bytes:
        """Розшифровує файл в пам'яті (AES-256-GCM) [cite: 18, 433]"""
        aesgcm = AESGCM(key)
        return aesgcm.decrypt(iv, ciphertext, None)
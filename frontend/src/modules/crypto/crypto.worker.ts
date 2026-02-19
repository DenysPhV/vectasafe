// src/modules/crypto/crypto.worker.ts
import { expose } from 'comlink';

const cryptoModule = {
  async generateUserKeys() {
    // Виклик WASM методу для генерації Ed25519/X25519
    // Посібник Частина 2.1: Client-Side KeyGen
    return await wasm.generate_keys();
  },

  async encryptFile(fileBuffer: ArrayBuffer, fileKey: Uint8Array) {
    // Реалізація AES-256-GCM шифрування через WASM
    // Складність O(n) 
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const ciphertext = await wasm.encrypt_gcm(fileBuffer, fileKey, iv);
    return { ciphertext, iv, tag: ciphertext.slice(-16) };
  }
};

expose(cryptoModule);
// src/modules/dashboard/components/SecureUploader.tsx
import React, { useState } from 'react';
import { useCrypto } from '../../crypto/hooks/useCrypto';
import { uploadService } from '../../../api/uploadService';

export const SecureUploader: React.FC = () => {
  const [progress, setProgress] = useState(0);
  const { encryptFile, wrapKey } = useCrypto();

  const handleUpload = async (file: File) => {
    // 1. Генеруємо симетричний FileKey (AES-256) [cite: 65, 250]
    const fileKey = window.crypto.getRandomValues(new Uint8Array(32));

    // 2. Шифруємо файл у Worker (WASM) [cite: 217]
    const { ciphertext, iv, tag } = await encryptFile(file, fileKey);

    // 3. Key Wrapping для себе та Адміна (Escrow) [cite: 138, 478]
    const wrappedKeys = await wrapKey(fileKey);

    // 4. Ініціація завантаження (отримання Pre-signed URL) [cite: 180]
    const { uploadUrl, fileId } = await uploadService.initUpload(file.name);

    // 5. Завантаження блоба в S3 [cite: 259]
    await uploadService.uploadToS3(uploadUrl, ciphertext, (p) => setProgress(p));

    // 6. Фіналізація метаданих [cite: 181]
    await uploadService.completeUpload({
      fileId,
      wrappedKeys,
      aesIv: iv,
      gcmTag: tag
    });
  };

  return (
    <div className="border-2 border-dashed border-blue-500 p-10 rounded-xl">
      {/* UI для Drag-n-Drop з ТЗ [cite: 503] */}
      <input type="file" onChange={(e) => e.target.files?.[0] && handleUpload(e.target.files[0])} />
      {progress > 0 && <progress value={progress} max="100" />}
    </div>
  );
};
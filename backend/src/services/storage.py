# src/services/storage.py
import aioboto3
from botocore.exceptions import ClientError
from config import settings

class StorageService:
    def __init__(self):
        self.session = aioboto3.Session()
        self.config = {
            "endpoint_url": settings.S3_ENDPOINT_URL,
            "aws_access_key_id": settings.S3_ACCESS_KEY,
            "aws_secret_access_key": settings.S3_SECRET_KEY,
            "region_name": settings.S3_REGION
        }

    async def generate_presigned_url(self, object_name: str, expiration=3600) -> str:
        """
        Генерує URL, куди фронтенд буде напряму заливати зашифрований файл.
        [cite_start][cite: 26] - вимога Upload API: pre-signed URL.
        """
        async with self.session.client("s3", **self.config) as s3:
            try:
                response = await s3.generate_presigned_url(
                    'put_object',
                    Params={
                        'Bucket': settings.S3_BUCKET_NAME,
                        'Key': object_name
                    },
                    ExpiresIn=expiration
                )
                return response
            except ClientError as e:
                print(f"S3 Error: {e}")
                return None

    async def download_file(self, object_name: str) -> bytes:
        """
        Завантажує файл у пам'ять для воркера.
        """
        async with self.session.client("s3", **self.config) as s3:
            try:
                # Отримуємо об'єкт
                response = await s3.get_object(
                    Bucket=settings.S3_BUCKET_NAME, 
                    Key=object_name
                )
                # Читаємо контент
                content = await response['Body'].read()
                return content
            except ClientError as e:
                print(f"Failed to download {object_name}: {e}")
                raise e
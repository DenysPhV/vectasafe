# VectaSafe
- Before to first start init 
`gcloud storage buckets create gs://vectasafe-tf-state-dev --project=vectasafe-infra --location=us-central1 --uniform-bucket-level-access` 
- Create secret remote
`gcloud secrets create vsafe-db-password --replication-policy="automatic"`

- Change YOUR_SECURE_PASSWORD on your real pass
`echo -n "YOUR_SECURE_PASSWORD" | gcloud secrets versions add vsafe-db-password --data-file=-`

- Migration state (if kyes alredy) Що треба зробити одразу після помилки (або перед apply)
  1. Імпорт в'язки
`terraform state mv google_kms_key_ring.vsafe_ring module.kms.google_kms_key_ring.key_ring`
  2. Імпорт ключа (якщо він теж існує)
`terraform state mv google_kms_crypto_key.vsafe_storage_key module.kms.google_kms_crypto_key.storage_key`

- Знайди ім'я інстансу
`gcloud compute instances list`
- Підключись
`gcloud compute ssh [ІМ'Я_ІНСТАНСУ] --zone=us-central1-a --tunnel-through-iap`

- Чи живий Docker-контейнер?
`sudo docker ps`
- Чому контейнер впав?
`sudo docker logs vectasafe_app`
- Чи взагалі відпрацював скрипт запуску?
`sudo journalctl -u google-startup-scripts.service -n 100`
- Чи працює Cloud SQL Proxy?
`systemctl status cloud-sql-proxy`


- Подивитись адреси
`gcloud compute forwarding-rules list --global`
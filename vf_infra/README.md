# VectaSafe
### Create secret remote
`gcloud secrets create vsafe-db-password --replication-policy="automatic"`

### Change YOUR_SECURE_PASSWORD on your real pass
`echo -n "YOUR_SECURE_PASSWORD" | gcloud secrets versions add vsafe-db-password --data-file=-`

### Migration state (if kyes alredy)
`terraform state mv google_kms_key_ring.vsafe_ring module.kms.google_kms_key_ring.key_ring`
`terraform state mv google_kms_crypto_key.vsafe_storage_key module.kms.google_kms_crypto_key.storage_key`
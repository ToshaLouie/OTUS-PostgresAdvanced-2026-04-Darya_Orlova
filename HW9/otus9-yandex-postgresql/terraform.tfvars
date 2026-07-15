# Obtain these IDs with:
# yc config get cloud-id
# yc config get folder-id

cloud_id             = "мой cloud id" ## использовала
folder_id            = "мой фолдер" ## использовала
yc_token             = "сгенерированный токен" ## использовала команду yc iam create-token
ssh_private_key_path = "~/.ssh/id_rsa"
zone                 = "ru-central1-e"

ssh_allowed_cidr      = ["0.0.0.0/0"]
postgres_allowed_cidr = ["0.0.0.0/0"]

bucket         = "dpn-tfstate-dev-001"
key            = "dev/terraform.tfstate"
region         = "eu-west-2"
dynamodb_table = "dpn-tfstate-lock-dev"
encrypt        = true
kms_key_id = "2b890774-bb2d-4c15-8e97-588da15cbf7d"
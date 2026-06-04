# Optional backend config for bootstrap after first local apply/import.
# Bootstrap usually starts with local state, then can be migrated to S3 if required.

bucket         = "dpn-tfstate-dev-001"
key            = "bootstrap/dev/terraform.tfstate"
region         = "eu-west-2"
dynamodb_table = "dpn-tfstate-lock-dev"
encrypt        = true

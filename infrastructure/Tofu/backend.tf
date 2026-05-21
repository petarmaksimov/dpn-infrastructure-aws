terraform {
  backend "s3" {
    # Set these values at init time or in backend.hcl
    # bucket         = "<state-bucket-name>"
    # key            = "tofu/aws/prod/terraform.tfstate"
    # region         = "eu-west-2"
    # dynamodb_table = "<state-lock-table>"
    # encrypt        = true
  }
}

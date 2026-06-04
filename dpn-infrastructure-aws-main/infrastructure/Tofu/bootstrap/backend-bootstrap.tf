# ==============================================================================
# Bootstrap Backend Configuration
# ==============================================================================
# The bootstrap uses LOCAL state during initial setup (chicken-and-egg problem).
# This ensures bootstrap can create the S3 backend without circular dependencies.
#
# IMPORTANT: After the bootstrap is deployed:
#   1. The S3 bucket and DynamoDB table will be created
#   2. You can then migrate bootstrap state to S3 (optional):
#      - Add backend block below (commented out)
#      - Run: tofu init -migrate-state
#      - Confirm the migration
#
# For production, consider migrating bootstrap state to S3 for:
#   - Centralized state management
#   - Remote backup
#   - Team collaboration
# ==============================================================================

# Local backend (default during bootstrap)
terraform {
  backend "local" {
    path = "bootstrap.tfstate"
  }
}

# ==============================================================================
# OPTIONAL: S3 Backend for Bootstrap (after initial deployment)
# ==============================================================================
# Uncomment the block below AFTER running the initial bootstrap deployment.
# This will migrate bootstrap state to S3 for better security and sharing.
#
# Steps to migrate:
#   1. Deploy bootstrap with local backend
#   2. Verify S3 bucket and DynamoDB table are created
#   3. Uncomment the block below
#   4. Run: tofu init
#   5. Confirm migration to S3
#
# terraform {
#   backend "s3" {
#     bucket         = "dpn-tfstate-bootstrap"
#     key            = "bootstrap/terraform.tfstate"
#     region         = "eu-west-2"
#     dynamodb_table = "dpn-tfstate-lock"
#     encrypt        = true
#   }
# }


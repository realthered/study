terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.0"
    }
  }
}

# Secrets are read from OS environment variables automatically:
#   export CONFLUENT_CLOUD_API_KEY="..."
#   export CONFLUENT_CLOUD_API_SECRET="..."
provider "confluent" {}

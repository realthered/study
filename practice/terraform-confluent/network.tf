resource "confluent_environment" "main" {
  display_name = local.environment_name

  stream_governance {
    package = "ESSENTIALS"
  }
}

resource "confluent_network" "main" {
  display_name     = "red-${local.environment_name}-network"
  cloud            = local.cloud_provider
  region           = local.cloud_region
  connection_types = ["INTERNET"]

  environment {
    id = confluent_environment.main.id
  }
}

resource "confluent_environment" "main" {
  display_name = local.environment_name

  stream_governance {
    package = "ESSENTIALS"
  }
}


locals {
  environment_name = "red-dev"
  cluster_name     = "red-dev-1"
  cloud_provider   = "AWS"
  cloud_region     = "ap-northeast-2"
  availability     = "SINGLE_ZONE"
  topic_names      = ["red-dev", "red-prod"]
  topic_partitions = 6

  common_tags = {
    environment = local.environment_name
    managed_by  = "terraform"
  }
}

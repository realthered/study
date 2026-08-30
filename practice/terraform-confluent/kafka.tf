# --- Cluster ---

resource "confluent_kafka_cluster" "main" {
  display_name = local.cluster_name
  availability = local.availability
  cloud        = local.cloud_provider
  region       = local.cloud_region

  basic {}

  environment {
    id = confluent_environment.main.id
  }

  network {
    id = confluent_network.main.id
  }
}

# --- Service Accounts ---

resource "confluent_service_account" "producer" {
  display_name = "${local.cluster_name}-producer"
  description  = "Service account for Kafka producers"
}

resource "confluent_service_account" "consumer" {
  display_name = "${local.cluster_name}-consumer"
  description  = "Service account for Kafka consumers"
}

# --- API Keys ---

resource "confluent_api_key" "producer_kafka" {
  display_name = "${local.cluster_name}-producer-kafka-api-key"
  description  = "Kafka API key for producer service account"

  owner {
    id          = confluent_service_account.producer.id
    api_version = confluent_service_account.producer.api_version
    kind        = confluent_service_account.producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.main.id
    api_version = confluent_kafka_cluster.main.api_version
    kind        = confluent_kafka_cluster.main.kind

    environment {
      id = confluent_environment.main.id
    }
  }
}

resource "confluent_api_key" "consumer_kafka" {
  display_name = "${local.cluster_name}-consumer-kafka-api-key"
  description  = "Kafka API key for consumer service account"

  owner {
    id          = confluent_service_account.consumer.id
    api_version = confluent_service_account.consumer.api_version
    kind        = confluent_service_account.consumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.main.id
    api_version = confluent_kafka_cluster.main.api_version
    kind        = confluent_kafka_cluster.main.kind

    environment {
      id = confluent_environment.main.id
    }
  }
}

# --- Topics ---

resource "confluent_kafka_topic" "topics" {
  for_each = toset(local.topic_names)

  topic_name       = each.key
  partitions_count = local.topic_partitions

  rest_endpoint = confluent_kafka_cluster.main.rest_endpoint

  kafka_cluster {
    id = confluent_kafka_cluster.main.id
  }

  credentials {
    key    = confluent_api_key.producer_kafka.id
    secret = confluent_api_key.producer_kafka.secret
  }

  config = {
    "retention.ms"   = "604800000" # 7 days
    "cleanup.policy" = "delete"
  }
}

# --- ACLs: Producer ---

resource "confluent_kafka_acl" "producer_write" {
  for_each = toset(local.topic_names)

  kafka_cluster {
    id = confluent_kafka_cluster.main.id
  }

  resource_type = "TOPIC"
  resource_name = each.key
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.producer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.main.rest_endpoint

  credentials {
    key    = confluent_api_key.producer_kafka.id
    secret = confluent_api_key.producer_kafka.secret
  }
}

# --- ACLs: Consumer ---

resource "confluent_kafka_acl" "consumer_read" {
  for_each = toset(local.topic_names)

  kafka_cluster {
    id = confluent_kafka_cluster.main.id
  }

  resource_type = "TOPIC"
  resource_name = each.key
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.main.rest_endpoint

  credentials {
    key    = confluent_api_key.producer_kafka.id
    secret = confluent_api_key.producer_kafka.secret
  }
}

resource "confluent_kafka_acl" "consumer_group" {
  kafka_cluster {
    id = confluent_kafka_cluster.main.id
  }

  resource_type = "GROUP"
  resource_name = "${local.cluster_name}-consumer-group"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.main.rest_endpoint

  credentials {
    key    = confluent_api_key.producer_kafka.id
    secret = confluent_api_key.producer_kafka.secret
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_client_config" "default" {}

# GKE Cluster
resource "google_container_cluster" "small_cluster" {
  name                     = "small-cluster-k8s"
  location                 = "us-central1-f"
  initial_node_count       = 1
  remove_default_node_pool = true

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # master_authorized_networks_config {
  #   cidr_blocks {
  #     cidr_block   = "0.0.0.0/0"
  #     display_name = "Any IP"
  #   }
  # }
}

# GKE Node Pool
resource "google_container_node_pool" "primary" {
  name       = "small-pool-k8s"
  location   = "us-central1-f"
  cluster    = google_container_cluster.small_cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-small"
    disk_size_gb = 10

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 3
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
# Get Cluster data after it's created
data "google_container_cluster" "cluster" {
  name     = google_container_cluster.small_cluster.name
  location = "us-central1-f"
  depends_on = [
    google_container_cluster.small_cluster
  ]
}

# Kubernetes provider configuration using the cluster data
provider "kubernetes" {
#  host                   = data.google_container_cluster.cluster.endpoint
  host                   = "https://${google_container_cluster.small_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)
}

# docker image deploy on GKE
resource "kubernetes_deployment" "app" {
  metadata {
    name = "fastapi-app-deployment"
    labels = {
      app = "fastapi-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "fastapi-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "fastapi-app"
        }
      }

      spec {
        container {
          image = "gcr.io/${var.project_id}/fastapi-app:latest" // reemplaza con la ruta a tu imagen
          name  = "fastapi-app"

          port {
            container_port = 8000 // reemplaza con el puerto que tu app escucha
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "fastapi-app-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.app.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 8000 // este debe ser el mismo puerto que definiste en tu Deployment
    }

    type = "LoadBalancer"
  }
}

# Cloud SQL Database
resource "google_sql_database_instance" "default" {
  name             = "postgres-instance"
  region           = var.region
  database_version = "POSTGRES_13"

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "default" {
  name     = "my-postgres-database"
  instance = google_sql_database_instance.default.name
}

# Load Balancer
resource "google_compute_forwarding_rule" "default" {
  name                  = "lb-rule"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_pool.default.self_link
}

resource "google_compute_target_pool" "default" {
  name = "target-pool"
  instances = [
    google_compute_instance.bastion_host.self_link
  ]
}

# # DNS Record
# resource "google_dns_record_set" "www" {
#   name         = "www.your-domain.com."
#   type         = "A"
#   ttl          = 300
#   managed_zone = "your-zone-name"
#   rrdatas      = [google_compute_forwarding_rule.default.IP_address]
# }

# Bastion Host
resource "google_compute_instance" "bastion_host" {
  name         = "bastion"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.bastion_image
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/pubsub",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}

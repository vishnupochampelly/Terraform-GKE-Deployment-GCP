# SIMPLE GKE CLUSTER (No secondary ranges)

resource "google_container_cluster" "gke_cluster" {
  name     = "gke-simple-cluster"
  location = "asia-south1-a"   # Zone
  project  = var.project

  network    = google_compute_network.gke_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  # PRIVATE NODES (nodes have no public IP)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # MASTER AUTHORIZED NETWORKS (ONLY YOUR IP CAN ACCESS)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "103.180.72.198/32"
      display_name = "home-ip"
    }
  }

  # WORKLOAD IDENTITY
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  depends_on = [
    google_compute_network.gke_vpc,
    google_compute_subnetwork.gke_subnet,
    google_compute_router_nat.gke_nat
  ]
}

# NODE POOL
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-nodepool"
  project    = var.project
  cluster    = google_container_cluster.gke_cluster.name
  location   = google_container_cluster.gke_cluster.location

  node_config {
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    tags = ["gke-node"]
  }

  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 2
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  depends_on = [
    google_container_cluster.gke_cluster
  ]
}

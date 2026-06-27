resource "google_compute_network" "gke_vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = "asia-south1"
  network       = google_compute_network.gke_vpc.id
}


# Allow GKE master to talk to nodes
resource "google_compute_firewall" "gke_master_access" {
  name    = "gke-master-access"
  network = google_compute_network.gke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["10250"]
  }

  source_ranges = ["172.16.0.0/28"] # Placeholder, updated after cluster creation

  depends_on = [
    google_compute_network.gke_vpc
  ]
}

# Allow health checks from Google Load Balancers
resource "google_compute_firewall" "gke_health_checks" {
  name    = "gke-health-checks"
  network = google_compute_network.gke_vpc.name

  allow {
    protocol = "tcp"
    ports = ["30000-32767"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  depends_on = [
    google_compute_network.gke_vpc
  ]
}

# Cloud Router
resource "google_compute_router" "gke_router" {
  name    = "gke-router"
  region  = "asia-south1"
  network = google_compute_network.gke_vpc.id
}

# Cloud NAT
resource "google_compute_router_nat" "gke_nat" {
  name                               = "gke-nat"
  router                             = google_compute_router.gke_router.name
  region                             = google_compute_router.gke_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  depends_on = [
    google_compute_router.gke_router
  ]
}

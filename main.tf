resource "google_compute_network" "vpc_network" {
  name                    = "dev-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet-a"
  ip_cidr_range = "10.0.0.1/22"
  network       = google_compute_network.vpc_network.id
}
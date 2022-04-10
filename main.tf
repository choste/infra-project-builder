resource "google_compute_network" "vpc_network" {
  name                    = "dev-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  #checkov:skip=CKV_GCP_26:Intentionally leaving off flow logs for now
  name                       = "subnet-a"
  ip_cidr_range              = "10.1.0.0/16"
  network                    = google_compute_network.vpc_network.id
  private_ip_google_access   = true
  private_ipv6_google_access = true
}

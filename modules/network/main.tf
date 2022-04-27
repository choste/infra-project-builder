resource "google_compute_network" "vpc" {
  name                    = "dev-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  #checkov:skip=CKV_GCP_26:Intentionally leaving off flow logs for now
  name                       = "subnet-a"
  ip_cidr_range              = "10.0.0.0/16"
  network                    = google_compute_network.vpc.id
  private_ip_google_access   = true
  private_ipv6_google_access = true
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.0.0/16"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "172.16.0.0/16"
  }
}

output "network_id" {
    value = google_compute_network.vpc.id
}

output "subnet_id" {
    value = google_compute_subnetwork.subnet.id
}

output "cluster_range" {
  value = google_compute_subnetwork.subnet.secondary_ip_range.0.range_name
}

output "service_range" {
  value = google_compute_subnetwork.subnet.secondary_ip_range.1.range_name
}
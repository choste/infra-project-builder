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

resource "google_container_cluster" "primary" {
  #checkov:skip=CKV_GCP_13:Leaving this enabled for ArgoCD Auth
  #checkov:skip=CKV_GCP_65:Leaving this off for now
  #chockov:skip=CKV_GCP_24:Leaving this off for now
  #checkov:skip=CKV_GCP_21:No labels yet
  #checkov:skip=CKV_GCP_66:Maybe someday
  #checkov:skip=CKV_GCP_19:False Positive
  #checkov:skip=CKV_GCP_20:No authorized networks yet
  #checkov:skip=CKV_GCP_24:False Positive
  count    = var.create_cluster ? 1 : 0
  name     = "${var.project}-gke"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnet.secondary_ip_range.0.range_name
    services_secondary_range_name = google_compute_subnetwork.subnet.secondary_ip_range.1.range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "10.1.0.0/28"
    master_global_access_config {
      enabled = true
    }
  }

  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  network_policy {
    enabled = true
  }

  enable_shielded_nodes       = true
  enable_intranode_visibility = true

  release_channel {
    channel = "REGULAR"
  }

  node_config {
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  count      = var.create_cluster ? 1 : 0
  name       = "${google_container_cluster.primary[0].name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary[0].name
  node_count = 1

  management {
    auto_upgrade = true
    auto_repair  = true
  }
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project
    }
    image_type   = "COS"
    preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.project}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}

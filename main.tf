module "network" {
  source = "./modules/network"

  project = var.project
  region  = var.region
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

  network    = module.network.network_id
  subnetwork = module.network.subnet_id

  ip_allocation_policy {
    cluster_secondary_range_name  = module.network.cluster_range
    services_secondary_range_name = module.network.service_range
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

resource "random_id" "id" {
  byte_length = 8
}

resource "google_project" "my_project" {
  name       = var.project
  project_id = "${var.project}-${random_id.id.hex}"
}
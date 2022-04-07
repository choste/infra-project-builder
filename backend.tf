terraform {
  backend "gcs" {
    bucket = "tf-state-backen"
    prefix = "/infra-project-builder/"
  }
}
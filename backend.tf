terraform {
    backend "gcs" {
        bucket = "soundcommerce-tf-admin"
        prefix = "/infra-project-builder/"
    }
}
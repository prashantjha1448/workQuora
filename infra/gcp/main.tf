provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

variable "gcp_project_id" {
  type    = string
  default = "workquora-prod"
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

resource "google_compute_network" "workquora_vpc" {
  name                    = "workquora-vpc"
  auto_create_subnetworks = true
}

output "network_self_link" {
  value = google_compute_network.workquora_vpc.self_link
}

terraform {
  required_version = ">= 1.0"

  backend "gcs" {
    bucket = "vectasafe-tf-state-unique-id" # Назва вашого GCS бакета
    prefix = "terraform/state"              # Шлях всередині бакета
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
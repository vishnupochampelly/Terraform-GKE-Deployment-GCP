terraform {
  backend "gcs" {
    bucket = "gke-tfstate-total-vertex-478310-e7"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "total-vertex-478310-e7"
  region  = "asia-south1"
}

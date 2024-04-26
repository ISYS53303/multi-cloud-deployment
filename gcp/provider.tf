terraform {
  required_version = ">= 0.12"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project     = "experiment-231217"
  region      = "us-central1"
  zone        = "us-central1-c"
  credentials = file("./gcp-key.json")
}

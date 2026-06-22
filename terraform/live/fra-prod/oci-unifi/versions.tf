terraform {
  required_version = ">= 1.10"

  backend "s3" {}

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "= 6.37.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

provider "cloudflare" {
  # reads CLOUDFLARE_API_TOKEN from environment
}

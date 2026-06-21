locals {
  common_tags = {
    Environment = "prod"
    Site        = "fra"
    ManagedBy   = "terraform"
    Owner       = "bearylabs"
  }
}

module "networking" {
  source = "../../../modules/oci/networking"

  compartment_id = var.compartment_id
  name_prefix    = "fra-prod"
  common_tags    = local.common_tags
}

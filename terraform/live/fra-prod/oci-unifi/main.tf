locals {
  common_tags = {
    Environment = "prod"
    Site        = "fra"
    Service     = "unifi"
    ManagedBy   = "terraform"
    Owner       = "bearylabs"
  }

  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_index].name
  image_id            = data.oci_core_images.ubuntu_arm.images[0].id
  user_data = base64encode(templatefile("${path.module}/templates/cloud-init.tftpl", {
    tailscale_auth_key = var.tailscale_auth_key
    tailscale_hostname = "fra-prod-unifi"
    unifi_deb_url      = var.unifi_deb_url
  }))
}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.networking_state_bucket
    key    = "fra-prod/oci-networking/terraform.tfstate"
    region = var.networking_state_region
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-24\\.04-aarch64.*"]
    regex  = true
  }
}

module "nsg" {
  source = "../../../modules/oci/nsg"

  compartment_id = var.compartment_id
  vcn_id         = data.terraform_remote_state.networking.outputs.vcn_id
  name_prefix    = "fra-prod-unifi"
  common_tags    = local.common_tags

  ingress_rules = {
    tailscale = {
      protocol = "17"
      source   = "0.0.0.0/0"
      port_min = 41641
      port_max = 41641
    }
    unifi_https = {
      protocol = "6"
      source   = "0.0.0.0/0"
      port_min = 443
      port_max = 443
    }
    unifi_portal = {
      protocol = "6"
      source   = "0.0.0.0/0"
      port_min = 11443
      port_max = 11443
    }
    unifi_inform = {
      protocol = "6"
      source   = "0.0.0.0/0"
      port_min = 8080
      port_max = 8080
    }
    unifi_stun = {
      protocol = "17"
      source   = "0.0.0.0/0"
      port_min = 3478
      port_max = 3478
    }
    unifi_discovery = {
      protocol = "17"
      source   = "0.0.0.0/0"
      port_min = 10001
      port_max = 10001
    }
  }
}

module "unifi" {
  source = "../../../modules/oci/compute"

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  subnet_id           = data.terraform_remote_state.networking.outputs.subnet_id
  nsg_ids             = [module.nsg.nsg_id]
  image_id            = local.image_id
  user_data           = local.user_data
  hostname            = "unifi"
  name_prefix         = "fra-prod"
  common_tags         = local.common_tags

  ocpus         = 2
  memory_in_gbs = 4
}

resource "cloudflare_dns_record" "unifi" {
  zone_id = var.cloudflare_zone_id
  name    = var.dns_record_name
  type    = "A"
  content = module.unifi.public_ip
  ttl     = 1      # auto (CF-managed)
  proxied = false  # UniFi devices must reach real IP for inform + STUN
  comment = "terraform managed"
}

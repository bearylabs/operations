resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = "${var.name_prefix}-${var.hostname}"
  shape               = var.shape
  freeform_tags       = var.common_tags

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    nsg_ids          = var.nsg_ids
    assign_public_ip = true
    hostname_label   = var.hostname
  }

  metadata = {
    user_data = var.user_data
  }

  preserve_boot_volume = false
}

data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"
}

locals {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_index].name
  ubuntu_image_id     = data.oci_core_images.ubuntu_arm.images[0].id
}

# Control plane — 2 OCPU / 12 GB (free tier: 4 OCPU / 24 GB total across all A1)
resource "oci_core_instance" "server" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  display_name        = "${var.cluster_name}-server"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  source_details {
    source_type             = "image"
    source_id               = local.ubuntu_image_id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = "${var.cluster_name}-server"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  freeform_tags = {
    role    = "server"
    cluster = var.cluster_name
  }
}

# Workers — 1 OCPU / 6 GB each (2× = remaining 2 OCPU / 12 GB)
resource "oci_core_instance" "workers" {
  count               = 2
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  display_name        = "${var.cluster_name}-worker-${count.index + 1}"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  source_details {
    source_type             = "image"
    source_id               = local.ubuntu_image_id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = "${var.cluster_name}-worker-${count.index + 1}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  freeform_tags = {
    role    = "worker"
    cluster = var.cluster_name
  }
}

# Write ansible inventory so the next step (ansible) picks up IPs automatically
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    server_ip  = oci_core_instance.server.public_ip
    worker_ips = [for w in oci_core_instance.workers : w.public_ip]
    ssh_user   = "ubuntu"
  })
  filename        = "${path.module}/../../../../ansible/inventories/fra-prod/hosts.ini"
  file_permission = "0644"
}

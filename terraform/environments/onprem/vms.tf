locals {
  template_vm_id = 9000
  gateway        = "10.8.10.1"
  dns_server     = "10.8.10.50"

  workers = {
    "worker-01" = { vm_id = 201, ip = "10.8.10.71" }
    "worker-02" = { vm_id = 202, ip = "10.8.10.72" }
  }
}

resource "proxmox_virtual_environment_vm" "server" {
  name      = "${var.cluster_name}-cp-01"
  node_name = var.proxmox_node
  vm_id     = 200

  clone {
    vm_id = local.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 32
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.8.10.70/24"
        gateway = local.gateway
      }
    }
    dns {
      servers = [local.dns_server]
    }
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
}

resource "proxmox_virtual_environment_vm" "workers" {
  for_each  = local.workers
  name      = "${var.cluster_name}-${each.key}"
  node_name = var.proxmox_node
  vm_id     = each.value.vm_id

  clone {
    vm_id = local.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 32
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = local.gateway
      }
    }
    dns {
      servers = [local.dns_server]
    }
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    cluster_name = var.cluster_name
    server_ip    = "10.8.10.70"
    worker_ips   = [for k, v in local.workers : v.ip]
    ssh_user     = "ubuntu"
  })
  filename        = "${path.module}/../../../ansible/inventory/onprem/hosts.ini"
  file_permission = "0644"
}

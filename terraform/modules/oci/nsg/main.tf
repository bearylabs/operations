resource "oci_core_network_security_group" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.name_prefix}-nsg"
  freeform_tags  = var.common_tags
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Allow all egress"
}

resource "oci_core_network_security_group_security_rule" "ingress" {
  for_each = var.ingress_rules

  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  source                    = each.value.source
  source_type               = "CIDR_BLOCK"
  description               = each.key

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.protocol == "17" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }
}

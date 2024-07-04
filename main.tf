######################
# Security List(s)
######################

locals {
  #general defaults
  compartment_id = try(data.oci_identity_compartments.compartment[0].compartments[0].id, var.compartment_id)
  vcn_id         = try(data.oci_core_vcns.vcns[0].virtual_networks[0].id, var.vcn_id)
  default_freeform_tags = {
    terraformed = "Please do not edit manually"
    module      = "oracle-terraform-oci-security-list"
  }
  merged_freeform_tags = merge(local.default_freeform_tags, var.freeform_tags)
  ingress_rules        = { for idx, ingress_rule in var.rules.ingress_rules : idx => ingress_rule }
  egress_rules         = { for idx, egress_rule in var.rules.egress_rules : idx => egress_rule }
}

# resource definitions
resource "oci_core_security_list" "main" {
  #Required
  compartment_id = local.compartment_id
  vcn_id         = local.vcn_id

  #Optional
  display_name  = var.display_name
  defined_tags  = var.defined_tags
  freeform_tags = local.merged_freeform_tags

  #ingress rules
  dynamic "ingress_security_rules" {
    for_each = local.ingress_rules

    content {
      #Required
      protocol = ingress_security_rules.value["protocol"]
      source   = ingress_security_rules.value["src"]

      #Optional
      description = ingress_security_rules.value["description"]
      source_type = ingress_security_rules.value["src_type"]
      stateless   = ingress_security_rules.value["stateless"]
      #tcp 
      dynamic "tcp_options" {
        for_each = ingress_security_rules.value["protocol"] == "6" ? { "tcp_options" = ingress_security_rules.value["dst_port"] } : {}

        content {
          #Optional
          max = tcp_options.value["max"]
          min = tcp_options.value["min"]

          dynamic "source_port_range" {
            for_each = ingress_security_rules.value["src_port"] != null ? { "src_port" = ingress_security_rules.value["src_port"] } : {}

            content {
              #Required
              max = source_port_range.value["max"]
              min = source_port_range.value["min"]
            }
          }
        }
      }
      dynamic "udp_options" {
        for_each = ingress_security_rules.value["protocol"] == "17" ? { "udp_options" = ingress_security_rules.value["dst_port"] } : {}

        content {
          #Optional
          max = tcp_options.value["max"]
          min = tcp_options.value["min"]
          dynamic "source_port_range" {
            for_each = udp_options.value["src_port"] != null ? { "src_port" = udp_options.value["src_port"] } : {}

            content {
              #Required
              max = source_port_range.value["max"]
              min = source_port_range.value["min"]
            }
          }
        }
      }
    }
  }
  #egress rules
  dynamic "egress_security_rules" {
    for_each = { for idx, egress_rule in var.rules.egress_rules : idx => egress_rule }

    content {
      #Required
      protocol    = egress_security_rules.value["protocol"]
      destination = egress_security_rules.value["dst"]

      #Optional
      description      = egress_security_rules.value["description"]
      destination_type = egress_security_rules.value["dst_type"]
      stateless        = egress_security_rules.value["stateless"]
      #tcp 
      dynamic "tcp_options" {
        for_each = egress_security_rules.value["protocol"] == "6" ? { "tcp_options" = egress_security_rules.value["dst_port"] } : {}

        content {
          #Optional
          max = tcp_options.value["max"]
          min = tcp_options.value["min"]

          dynamic "source_port_range" {
            for_each = egress_security_rules.value["src_port"] != null ? { "src_port" = egress_security_rules.value["src_port"] } : {}

            content {
              #Required
              max = source_port_range.value["max"]
              min = source_port_range.value["min"]
            }
          }
        }
      }
      dynamic "udp_options" {
        for_each = egress_security_rules.value["protocol"] == "17" ? { "udp_options" = egress_security_rules.value["dst_port"] } : {}

        content {
          #Optional
          max = tcp_options.value["max"]
          min = tcp_options.value["min"]

          dynamic "source_port_range" {
            for_each = egress_security_rules.value["src_port"] != null ? { "src_port" = egress_security_rules.value["src_port"] } : {}

            content {
              #Required
              max = source_port_range.value["max"]
              min = source_port_range.value["min"]
            }
          }
        }
      }
    }
  }
}

# OCI Security List Terraform Module

This Terraform module provisions Security Lists in Oracle Cloud Infrastructure (OCI).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Files](#files)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) 0.12 or later
- Oracle Cloud Infrastructure account credentials

## Usage

To use this module, include the following code in your Terraform configuration:

```hcl
module "oci_security_list" {
  source = "path_to_this_module"

  # Define the necessary variables
  tenancy_ocid    = var.tenancy_ocid
  compartment_id  = var.compartment_id
  compartment     = var.compartment
  vcn_id          = var.vcn_id
  vcn_name        = var.vcn_name
  display_name    = var.display_name
  freeform_tags   = var.freeform_tags
  defined_tags    = var.defined_tags
  rules           = var.rules
}
```

## Files

- `variables.tf`: Defines input variables.
- `main.tf`: Main Terraform configuration for setting up the security list.
- `output.tf`: Defines output values to be exported.
- `datasources.tf`: Configuration for data sources to be used in the module.

### main.tf

```hcl
locals {
  compartment_id = try(data.oci_identity_compartments.compartment[0].compartments[0].id, var.compartment_id)
  vcn_id         = try(data.oci_core_vcns.vcns[0].virtual_networks[0].id, var.vcn_id)
  default_freeform_tags = {
    terraformed = "Please do not edit manually"
    module      = "oracle-terraform-oci-security-list"
  }
  merged_freeform_tags = merge(local.default_freeform_tags, var.freeform_tags)
  ingress_rules = { for idx, ingress_rule in var.rules.ingress_rules : idx => ingress_rule }
  egress_rules  = { for idx, egress_rule in var.rules.egress_rules : idx => egress_rule }
}

resource "oci_core_security_list" "main" {
  compartment_id = local.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.display_name
  defined_tags   = var.defined_tags
  freeform_tags  = local.merged_freeform_tags

  dynamic "ingress_security_rules" {
    for_each = local.ingress_rules
    content {
      protocol = ingress_security_rules.value["protocol"]
      source   = ingress_security_rules.value["src"]
      description = ingress_security_rules.value["description"]
      source_type = ingress_security_rules.value["src_type"]
      stateless   = ingress_security_rules.value["stateless"]
      dynamic "tcp_options" {
        for_each = ingress_security_rules.value["protocol"] == "6" ? { "tcp_options" = ingress_security_rules.value["dst_port"] } : {}
        content {
          max = tcp_options.value["max"]
          min = tcp_options.value["min"]
          dynamic "source_port_range" {
            for_each = ingress_security_rules.value["src_port"] != null ? { "src_port" = ingress_security_rules.value["src_port"] } : {}
            content {
              max = source_port_range.value["max"]
              min = source_port_range.value["min"]
            }
          }
        }
      }
      dynamic "udp_options" {
        for_each = ingress_security_rules.value["protocol"] == "17" ? { "udp_options" = ingress_security_rules.value["dst_port"] } : {}
        content {
          max = tcp_options.value["max"]
          min = tcp_options.value["min"]
          dynamic "source_port_range" {
            for_each = udp_options.value["src_port"] != null ? { "src_port" = udp_options.value["src_port"] } : {}
            content {
              max = source_port_range.value["max"]
              min = source_port_range.value["min"]
            }
          }
        }
      }
    }
  }
  
  dynamic "egress_security_rules" {
    for_each = local.egress_rules
    content {
      protocol    = egress_security_rules.value["protocol"]
      destination = egress_security_rules.value["dst"]
      description      = egress_security_rules.value["description"]
      destination_type = egress_security_rules.value["dst_type"]
      stateless        = egress_security_rules.value["stateless"]
      dynamic "tcp_options" {
        for_each = egress_security_rules.value["protocol"] == "6" ? { "tcp_options" = egress_security_rules.value["dst_port"] } : {}
        content {
          max = tcp_options.value["max"]
          min = tcp_options.value["min"]
          dynamic "source_port_range" {
            for_each = egress_security_rules.value["src_port"] != null ? { "src_port" = egress_security_rules.value["src_port"] } : {}
            content {
              max = source_port_range.value["max"]
              min = source_port_range.value["min"]
            }
          }
        }
      }
      dynamic "udp_options" {
        for_each = egress_security_rules.value["protocol"] == "17" ? { "udp_options" = egress_security_rules.value["dst_port"] } : {}
        content {
          max = tcp_options.value["max"]
          min = tcp_options.value["min"]
          dynamic "source_port_range" {
            for_each = udp_options.value["src_port"] != null ? { "src_port" = udp_options.value["src_port"] } : {}
            content {
              max = source_port_range.value["max"]
              min = source_port_range.value["min"]
            }
          }
        }
      }
    }
  }
}
```

### output.tf

```hcl
output "id" {
  value = oci_core_security_list.main.id
}
```

### variables.tf

```hcl
variable "tenancy_ocid" {
  description = "(Required) (Updatable) The OCID of the root compartment."
  type        = string
  default     = null
}

variable "compartment_id" {
  type        = string
  description = "The default compartment OCID to use for resources (unless otherwise specified)."
  default     = null
}

variable "compartment" {
  description = "Compartment name where to create all resources."
  type        = string
  default     = null
}

variable "vcn_id" {
  type        = string
  description = "The VCN ID where the Security List(s) should be created."
  default     = null
}

variable "vcn_name" {
  type        = string
  description = "The VCN name where the Security List(s) should be created."
  default     = null
}

variable "display_name" {
  description = "(Optional) (Updatable) A user-friendly name. Does not have to be unique, and it's changeable. Avoid entering confidential information."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Simple key-value pairs to tag the resources created using freeform tags."
  type        = map(string)
  default     = null
}

variable "defined_tags" {
  description = "Predefined and scoped to a namespace to tag the resources created using defined tags."
  type        = map(string)
  default     = null
}

variable "rules" {
  type = object({
    ingress_rules = list(object({
      description = string,
      stateless   = optional(bool, false),
      protocol    = optional(string, "6"),
      src         = string,
      src_type    = optional(string, "CIDR_BLOCK"),
      src_port    = optional(object({
        min = number,
        max = number
      }), null),
      dst_port    = optional(object({
        min = number,
        max = number
      }), null),
      icmp_type   = optional(number, null),
      icmp_code   = optional(number, null)
    })),
    egress_rules = list(object({
      description = string,
      stateless   = optional(bool, false),
      protocol    = optional(string, "6"),
      dst         = string,
      dst_type    = optional(string, "CIDR_BLOCK"),
      src_port    = optional(object({
        min = number,
        max = number
      }), null),
      dst_port    = optional(object({
        min = number,
        max = number
      }), null),
      icmp_type   = optional(number, null),
      icmp_code   = optional(number, null)
    }))
  })
  default = null
}
```

### datasources.tf

```hcl
data "oci_identity_compartments" "compartment" {
  count = var.tenancy_ocid == null ? 0 : 1
  compartment_id            = var.tenancy_ocid
  access_level              = "ANY"
  compartment_id_in_subtree = true

  filter {
    name   = "state"
    values = ["ACTIVE"]
  }

  filter {
    name   = "name"
    values = [var.compartment]
  }
}

data "oci_core_vcns" "vcns" {
  count = var.vcn_name == null ? 0 : 1
  compartment_id = local.compartment_id
  display_name   = var.vcn_name
  depends_on     = [data.oci_identity_compartments.compartment]
}
```

## Inputs



| Name            | Description                                                          | Type       | Default | Required |
|-----------------|----------------------------------------------------------------------|------------|---------|----------|
| tenancy_ocid    | (Required) (Updatable) The OCID of the root compartment.             | `string`   | `null`  | yes      |
| compartment_id  | The default compartment OCID to use for resources.                   | `string`   | `null`  | yes      |
| compartment     | Compartment name where to create all resources.                      | `string`   | `null`  | yes      |
| vcn_id          | The VCN ID where the Security List(s) should be created.             | `string`   | `null`  | yes      |
| vcn_name        | The VCN name where the Security List(s) should be created.           | `string`   | `null`  | yes      |
| display_name    | (Optional) A user-friendly name.                                     | `string`   | `null`  | no       |
| freeform_tags   | Simple key-value pairs to tag the resources created using freeform tags. | `map(string)` | `null`  | no       |
| defined_tags    | Predefined and scoped to a namespace to tag the resources created using defined tags. | `map(string)` | `null`  | no       |
| rules           | Rules for ingress and egress security lists.                         | `object`   | `null`  | yes      |

## Outputs

| Name           | Description                              |
|----------------|------------------------------------------|
| id             | The ID of the created security list      |

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any bugs, feature requests, or enhancements.

## License

This project is licensed under the Universal Permissive License v 1.0. See the [LICENSE](https://oss.oracle.com/licenses/upl) file for details.
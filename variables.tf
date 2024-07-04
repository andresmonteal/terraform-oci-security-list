# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

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
  description = "compartment name where to create all resources"
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
  description = "simple key-value pairs to tag the resources created using freeform tags."
  type        = map(string)
  default     = null
}

variable "defined_tags" {
  description = "predefined and scoped to a namespace to tag the resources created using defined tags."
  type        = map(string)
  default     = null
}

variable "rules" {
  type = object({
    ingress_rules = list(object({
      description = string,
      stateless   = optional(bool, false),
      # Options are supported only for ICMP ("1"), TCP ("6"), UDP ("17"), and ICMPv6 ("58").
      protocol = optional(string, "6"),
      src      = string,
      # Allowed values: CIDR_BLOCK, SERVICE_CIDR_BLOCK, NETWORK_SECURITY_GROUP, NSG_NAME
      src_type = optional(string, "CIDR_BLOCK"),
      src_port = optional(object({
        min = number,
        max = number
      }), null),
      dst_port = optional(object({
        min = number,
        max = number
      }), null),
      icmp_type = optional(number, null),
      icmp_code = optional(number, null)
    })),
    egress_rules = list(object({
      description = string,
      stateless   = optional(bool, false),
      # Options are supported only for ICMP ("1"), TCP ("6"), UDP ("17"), and ICMPv6 ("58").
      protocol = optional(string, "6"),
      dst      = string,
      # Allowed values: CIDR_BLOCK, SERVICE_CIDR_BLOCK, NETWORK_SECURITY_GROUP, NSG_NAME
      dst_type = optional(string, "CIDR_BLOCK"),
      src_port = optional(object({
        min = number,
        max = number
      }), null),
      dst_port = optional(object({
        min = number,
        max = number
      }), null),
      icmp_type = optional(number, null),
      icmp_code = optional(number, null)
    }))
  })
  default = null
}
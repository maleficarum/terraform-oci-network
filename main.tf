resource "oci_identity_compartment" "network_compartment" {
  count = var.compartment_id != "" ? 1 : 0

  compartment_id = var.compartment_id
  description    = "Compartment for network resources"
  name           = "network"
}

resource "oci_core_vcn" "vcn" {
  cidr_block     = var.vcn_definition.cidr_block
  display_name   = var.vcn_definition.name
  compartment_id = local.compartment_id
  dns_label      = var.vcn_definition.dns_label

  freeform_tags = {
  }

  defined_tags = {}

}

resource "oci_core_subnet" "public_subnet" {
  count = length(var.public_subnet_definition)

  cidr_block     = var.public_subnet_definition[count.index].cidr_block
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.public_subnet_definition[count.index].name

  route_table_id = oci_core_route_table.public_route_table.id

  security_list_ids = compact(concat(
    [
      for security_rule in var.public_security_rules :
      oci_core_security_list.public_security_list[index(var.public_security_rules, security_rule)].id
      if security_rule.subnetwork_name == var.public_subnet_definition[count.index].name
    ],
    [oci_core_default_security_list.vcn_security_list.id]
  ))

  freeform_tags = {
  }


}

resource "oci_core_subnet" "private_subnet" {
  count = length(var.private_subnet_definition)

  cidr_block                 = var.private_subnet_definition[count.index].cidr_block
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = var.private_subnet_definition[count.index].name
  prohibit_public_ip_on_vnic = true

  route_table_id            = oci_core_route_table.private_route_table.id
  prohibit_internet_ingress = "true"
  dns_label                 = var.private_subnet_definition[count.index].dns_label

  security_list_ids = compact(concat(
    [
      for security_rule in var.private_security_rules :
      oci_core_security_list.private_security_list[index(var.private_security_rules, security_rule)].id
      if security_rule.subnetwork_name == var.private_subnet_definition[count.index].name
    ],
    [oci_core_default_security_list.vcn_security_list.id]
  ))

  freeform_tags = {
  }

  defined_tags = {}
}

resource "oci_core_route_table" "public_route_table" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_definition.name}-public_route-table"

  # route_rules {
  #   network_entity_id = oci_core_internet_gateway.internet_gateway.id
  #   description       = "Internet Gateway"
  #   destination       = "0.0.0.0/0"
  #   destination_type  = "CIDR_BLOCK"
  # }

  dynamic "route_rules" {
    for_each = var.public_route_rules

    content {
      destination       = route_rules.value.network_entity == "SRVC" ? data.oci_core_services.all_services.services[0]["cidr_block"] :route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity == "INET" ? oci_core_internet_gateway.internet_gateway.id : (route_rules.value.network_entity == "SRVC" ? oci_core_service_gateway.service_gateway.id : route_rules.value.network_entity)
      description       = route_rules.value.description
    }
  }

  freeform_tags = {
  }

  defined_tags = {}

}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  display_name = "${var.vcn_definition.name}-private-route-table"

  dynamic "route_rules" {
    for_each = var.private_route_rules

    content {
      destination       = route_rules.value.network_entity == "SRVC" ? data.oci_core_services.all_services.services[0]["cidr_block"] :route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity == "NAT" ? oci_core_nat_gateway.nat_gateway.id : (route_rules.value.network_entity == "SRVC" ? oci_core_service_gateway.service_gateway.id : route_rules.value.network_entity)
      description       = route_rules.value.description
    }
  }

  freeform_tags = {
  }

  # defined_tags = {
  #   "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
  #   "Oracle-Tags.Environment" = var.environment
  #   "Oracle-Tags.Application" = var.application_name
  # }
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  enabled      = true
  display_name = "${var.vcn_definition.name}-igw"

  freeform_tags = {
  }

}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  block_traffic = false
  display_name  = "${var.vcn_definition.name}-nat-gwy"

  freeform_tags = {
  }

}

resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_definition.name}-service-gateway"

  services {
    # Typically you'll use the "All Services" option
    service_id = data.oci_core_services.all_services.services[0].id
  }

  route_table_id = oci_core_vcn.vcn.default_route_table_id

}

# resource "oci_core_drg" "drg" {
#   count = var.vcn_definition.has_drg

#   compartment_id = var.compartment_id
#   display_name   = "example-drg"
  
#   # Optional parameters
#   defined_tags   = var.defined_tags
#   freeform_tags  = var.freeform_tags
# }

resource "oci_core_default_security_list" "vcn_security_list" {
  compartment_id = local.compartment_id
  display_name   = "Default Security List for ${var.vcn_definition.name}"

  freeform_tags = {
  }

  #Mandaroty rule
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }

  egress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol         = "1"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
  }

  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
}

# type = list(object({

#   rules = list(object({
#     description = string,
#     protocol    = string,
#     source      = string,
#     source_type = string,
#     stateless   = string,
#     tcp_options = object({
#       max = string,
#       min = string
#     })
#   }))
# }))

resource "oci_core_security_list" "private_security_list" {
  count          = length(var.private_security_rules)
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.private_security_rules[count.index].security_list_name

  #TODO: Agregar egress rules

  dynamic "ingress_security_rules" {
    for_each = var.private_security_rules[count.index].rules
    content {
      description = ingress_security_rules.value.description
      protocol    = ingress_security_rules.value.protocol
      source      = ingress_security_rules.value.source
      source_type = ingress_security_rules.value.source_type
      stateless   = ingress_security_rules.value.stateless

      tcp_options {
        min = ingress_security_rules.value.tcp_options.min
        max = ingress_security_rules.value.tcp_options.max
      }
    }
  }
}

resource "oci_core_security_list" "public_security_list" {
  count          = length(var.public_security_rules)
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.public_security_rules[count.index].security_list_name

  #TODO: Agregar egress rules

  dynamic "ingress_security_rules" {
    for_each = var.public_security_rules[count.index].rules
    content {
      description = ingress_security_rules.value.description
      protocol    = ingress_security_rules.value.protocol
      source      = ingress_security_rules.value.source
      source_type = ingress_security_rules.value.source_type
      stateless   = ingress_security_rules.value.stateless

      tcp_options {
        min = ingress_security_rules.value.tcp_options.min
        max = ingress_security_rules.value.tcp_options.max
      }
    }
  }
}
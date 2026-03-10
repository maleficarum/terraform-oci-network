# Author: Oscar I Hernandez

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

  freeform_tags = var.vcn_definition.freeform_tags

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
  }

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

  freeform_tags = var.public_subnet_definition[count.index].freeform_tags
  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
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

  freeform_tags = var.private_subnet_definition[count.index].freeform_tags
  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
  }
}

resource "oci_core_route_table" "public_route_table" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_definition.name}-public_route-table"

  dynamic "route_rules" {
    for_each = var.public_route_rules

    content {
      destination       = route_rules.value.network_entity == "SRVC" ? data.oci_core_services.all_services.services[0]["cidr_block"] : route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity == "INET" ? oci_core_internet_gateway.internet_gateway.id : (route_rules.value.network_entity == "SRVC" ? oci_core_service_gateway.service_gateway.id : route_rules.value.network_entity)
      description       = route_rules.value.description
    }
  }

  freeform_tags = var.vcn_definition.freeform_tags
  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
  }

}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  display_name = "${var.vcn_definition.name}-private-route-table"

  dynamic "route_rules" {
    for_each = var.private_route_rules

    content {
      destination       = route_rules.value.network_entity == "SRVC" ? data.oci_core_services.all_services.services[0]["cidr_block"] : route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity == "NAT" ? oci_core_nat_gateway.nat_gateway.id : (route_rules.value.network_entity == "SRVC" ? oci_core_service_gateway.service_gateway.id : route_rules.value.network_entity)
      description       = route_rules.value.description
    }
  }

  freeform_tags = var.vcn_definition.freeform_tags
  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
  }
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  enabled      = true
  display_name = "${var.vcn_definition.name}-igw"

  freeform_tags = var.vcn_definition.freeform_tags
  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
  }

}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  block_traffic = false
  display_name  = "${var.vcn_definition.name}-nat-gwy"

  freeform_tags = var.vcn_definition.freeform_tags
  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
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

  freeform_tags = var.vcn_definition.freeform_tags
  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
  }

}

# resource "oci_core_drg" "drg" {
#   count = var.vcn_definition.has_drg == true ? 1 : 0

#   compartment_id = local.compartment_id
#   display_name   = "DRG for ${var.vcn_definition.name}"

#   # Optional parameters
#   #defined_tags   = var.defined_tags
#   #freeform_tags  = var.freeform_tags
# }

# resource "oci_core_drg_attachment" "vcn_drg_attachment" {
#   count = var.vcn_definition.has_drg == true ? 1 : 0

#   drg_id         = oci_core_drg.drg[count.index].id
#   vcn_id         = oci_core_vcn.vcn.id
#   route_table_id = oci_core_route_table.drg_route_table[count.index].id
#   display_name   = "drg-attachment-with-custom-rt"
# }

# resource "oci_core_route_table" "drg_route_table" {
#   count = var.vcn_definition.has_drg == true ? 1 : 0

#   compartment_id = local.compartment_id
#   vcn_id         = oci_core_vcn.vcn.id
#   display_name   = "drg-route-table"

#   #TODO: ESto en teoria lo hace automaticamente la creacion del DRG
#   # route_rules {
#   #   destination       = "10.10.0.0/16"#TODO: esto debe estar como destino en la configuracion
#   #   destination_type  = "DYNAMIC"
#   #   network_entity_id = oci_core_drg.drg[count.index].id
#   # }

#   #TODO: Esto debe ser por cada subred
#   # route_rules {
#   #   destination       = oci_core_subnet.private_subnet[count.index].cidr_block
#   #   destination_type  = "DYNAMIC"
#   #   network_entity_id = oci_core_subnet.private_subnet[count.index].id
#   # }

# }

# #TODO: Deben existir dos statements, uno por VCN y uno para todo lo demas
# resource "oci_core_drg_route_distribution" "test_drg_route_distribution" {
#   #Required
#   distribution_type = var.drg_route_distribution_distribution_type
#   drg_id            = oci_core_drg.test_drg.id

#   display_name = var.drg_route_distribution_display_name
# }

# #TODO: para all debe existir un statement.
# resource "oci_core_drg_route_distribution_statement" "test_drg_route_distribution_statement" {
#   #Required
#   drg_route_distribution_id = oci_core_drg_route_distribution.test_drg_route_distribution.id
#   action                    = var.drg_route_distribution_statement_statements_action
#   #Optional
#   match_criteria {
#     #Required
#     match_type = var.drg_route_distribution_statement_statements_match_criteria_match_type

#     #Optional
#     attachment_type   = var.drg_route_distribution_statement_statements_match_criteria_attachment_type
#     drg_attachment_id = oci_core_drg_attachment.test_drg_attachment.id
#   }
#   priority = var.drg_route_distribution_statement_statements_priority

# }

resource "oci_core_default_security_list" "vcn_security_list" {
  compartment_id = local.compartment_id
  display_name   = "Default Security List for ${var.vcn_definition.name}"



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

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
  }
  freeform_tags = var.vcn_definition.freeform_tags

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
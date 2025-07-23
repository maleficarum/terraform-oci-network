resource "oci_core_vcn" "vcn" {
  cidr_block     = var.vcn_definition.cidr_block
  display_name   = var.vcn_definition.name
  compartment_id = var.compartment_id
  dns_label      = var.vcn_definition.dbs_label

  freeform_tags = {
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }

}

resource "oci_core_subnet" "public_subnet" {
  cidr_block     = var.public_subnet_definition.cidr_block
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.public_subnet_definition.name

  route_table_id = oci_core_route_table.public_route_table.id

  freeform_tags = {
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block                 = var.private_subnet_definition.cidr_block
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = var.private_subnet_definition.name
  prohibit_public_ip_on_vnic = true

  route_table_id            = oci_core_route_table.private_route_table.id
  prohibit_internet_ingress = "true"

  freeform_tags = {
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }
}

#resource "oci_core_public_ip" "vm_public_ip" {
#  count                = var.public_reserved_ips
#  compartment_id = var.compartment_id
#  lifetime      = "RESERVED"
#  display_name  = "reserved-public-ip${count.index}"
#}

resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_definition.name}-public_route-table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
    description       = "Internet Gateway"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  freeform_tags = {
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }

}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  display_name = "${var.vcn_definition.name}-private-route-table"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
    description       = "Route for Nat Gateway"
  }

  freeform_tags = {
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  enabled      = true
  display_name = "${var.vcn_definition.name}-igw"

  freeform_tags = {
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }
}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  block_traffic = false
  display_name  = "${var.vcn_definition.name}-nat-gwy"

  freeform_tags = {
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }
}

resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_definition.name}-service-gateway"

  services {
    # Typically you'll use the "All Services" option
    service_id = data.oci_core_services.all_services.services[0].id
  }

  route_table_id = oci_core_vcn.vcn.default_route_table_id

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }
}

resource "oci_core_default_security_list" "security_list" {
  compartment_id = var.compartment_id
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

  dynamic "egress_security_rules" {
    for_each = var.egress_security_rules

    content {
      protocol    = egress_security_rules.value.protocol
      destination = egress_security_rules.value.public_subnet ? oci_core_subnet.public_subnet.cidr_block : oci_core_subnet.private_subnet.cidr_block
      stateless   = false
    }
  }

  /*
  egress_security_rules {
    protocol    = "6" # TCP protocol (IANA number for TCP)
    destination = oci_core_subnet.private_subnet.cidr_block
    stateless   = false
    tcp_options {
      min = 32767
      max = 60999
    }
  }*/

  ingress_security_rules {
    description = "All inter-worker pod communication"
    protocol    = "all"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }

  #Mandatory rule
  ingress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }

  #Mandatory rule
  ingress_security_rules {
    icmp_options {
      code = "-1"
      type = "3"
    }

    protocol    = "1"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }

  dynamic "ingress_security_rules" {
    for_each = var.ingress_security_rules

    content {
      protocol    = ingress_security_rules.value.protocol
      source      = ingress_security_rules.value.source
      source_type = ingress_security_rules.value.source_type
      stateless   = ingress_security_rules.value.stateless

      tcp_options {
        max = ingress_security_rules.value.tcp_options.max
        min = ingress_security_rules.value.tcp_options.max
      }
    }
  }

  /*
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"

    tcp_options {
      max = "6443"
      min = "6443"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"

    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"

    tcp_options {
      max = "6379"
      min = "6379"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"

    tcp_options {
      max = "12250"
      min = "12250"
    }
  }  
  */

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }

  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
}
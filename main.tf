resource "oci_core_vcn" "vcn" {
  cidr_block     = var.vcn_definition.cidr_block
  display_name   = var.vcn_definition.name
  compartment_id = var.compartment_id
}

resource "oci_core_subnet" "public_subnet" {
  cidr_block              = var.public_subnet_definition.cidr_block
  compartment_id          = var.compartment_id
  vcn_id                  = oci_core_vcn.vcn.id
  display_name            = var.public_subnet_definition.name
  prohibit_public_ip_on_vnic = false  # Allow public IP addresses
  availability_domain      = data.oci_identity_availability_domains.oci_identity_availability_domain.availability_domains[0].name

  #route_table_id          = oci_core_route_table.public_route_table.id
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block              = var.private_subnet_definition.cidr_block
  compartment_id          = var.compartment_id
  vcn_id                  = oci_core_vcn.vcn.id
  display_name            = var.private_subnet_definition.name
  prohibit_public_ip_on_vnic = true  # Block public IP addresses
  availability_domain      = data.oci_identity_availability_domains.oci_identity_availability_domain.availability_domains[0].name

  #route_table_id          = oci_core_route_table.route_table.id
}

resource "oci_core_internet_gateway" "internet_gateway" {
    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.vcn.id

    enabled = true
    display_name = "${var.vcn_definition.name}-igw"
    #route_table_id = oci_core_route_table.public_route_table.id
}

resource "oci_core_nat_gateway" "nat_gateway" {
    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.vcn.id

    block_traffic = false
    display_name = "${var.vcn_definition.name}-nat-gwy"
}

resource "oci_core_route_table" "public_route_table" {
    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.vcn.id

    display_name = "${var.vcn_definition.name}-public_route-table"
    route_rules {
        destination = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        network_entity_id = oci_core_internet_gateway.internet_gateway.id
        description = "Route for Nat Gateway"
    }
}

resource "oci_core_route_table" "private_route_table" {
    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.vcn.id

    display_name = "${var.vcn_definition.name}-private-route-table"
    route_rules {
        destination = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        network_entity_id = oci_core_nat_gateway.nat_gateway.id
        description = "Route for Nat Gateway"
    }
}
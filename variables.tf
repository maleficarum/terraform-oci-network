variable "environment" {
  type        = string
  description = "The target environment (qa, development, production)"
}
variable "vcn_definition" {
  description = "VCN Definition"
  type = object({
    cidr_block = string,
    name       = string,
    dns_label  = string
  })
}

variable "private_subnet_definition" {
  description = "Private subnets Definition"
  type = list(object({
    cidr_block = string,
    name       = string
  }))
}

variable "public_subnet_definition" {
  description = "Public subnets Definition"
  type = list(object({
    cidr_block = string,
    name       = string
  }))
}

#variable "public_reserved_ips" {
#  description = "The total public IP reservations"
#  type = number
#  default = 2
#}

variable "compartment_id" {
  type        = string
  default     = ""
  description = "Parent compartment (OCID) where all the sub-compartments will be created (networking, compute)"
}

variable "existing_compartment" {
  type        = string
  default     = ""
  description = "The existing compartment where the network resources should be created. If this si set, the compartment_id variable should be empty"
}

variable "ingress_security_rules" {
  description = "Ingress list for the VCN"
  type = list(object({
    description = string,
    protocol    = string,
    source      = string,
    source_type = string,
    stateless   = string,
    tcp_options = object({
      max = string,
      min = string
    })
  }))
}

variable "egress_security_rules" {
  description = "Egress list for the VCN"
  type = list(object({
    description   = string,
    protocol      = string,
    stateless     = string,
    public_subnet = bool,
    tcp_options = object({
      max = string,
      min = string
    })
  }))
}

variable "application_name" {
  type        = string
  default     = "General"
  description = "The application name that will be deployed over this resource"
}

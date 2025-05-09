variable "environment" {
  type        = string
  description = "The target environment"
}
variable "vcn_definition" {
  description = "VCN Definition"
  type = object({
    cidr_block = string,
    name       = string,
    dbs_label  = string
  })
}

variable "private_subnet_definition" {
  description = "Private subnet Definition"
  type = object({
    cidr_block = string,
    name       = string
  })
}

variable "public_subnet_definition" {
  description = "Public subnet Definition"
  type = object({
    cidr_block = string,
    name       = string
  })
}

variable "compartment_id" {
  type        = string
  description = "Compartment to deploy"
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

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

variable "test" {
  type = string
}

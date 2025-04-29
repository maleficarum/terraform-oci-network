# tflint-ignore: terraform_unused_declarations
data "oci_identity_availability_domains" "oci_identity_availability_domain" {
  compartment_id = var.compartment_id
}
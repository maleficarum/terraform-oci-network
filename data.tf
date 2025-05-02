# tflint-ignore: terraform_unused_declarations
data "oci_identity_availability_domains" "oci_identity_availability_domain" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "oke_worker_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"  # or "7", "9"
  filter {
    name   = "display_name"
    values = ["^Oracle-Linux-.*-OKE-.*"]
    regex  = true
  }
}
# tflint-ignore: terraform_unused_declarations
data "oci_identity_availability_domains" "oci_identity_availability_domain" {
  compartment_id = local.compartment_id
}

data "oci_core_images" "oke_worker_images" {
  compartment_id           = local.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8" # or "7", "9"
  filter {
    name   = "display_name"
    values = ["^Oracle-Linux-.*-OKE-.*"]
    regex  = true
  }
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

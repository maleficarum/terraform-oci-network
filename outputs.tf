
# tflint-ignore: terraform_unused_declarations
output "ad" {
  value       = data.oci_identity_availability_domains.oci_identity_availability_domain
  description = "The existing AD within the specified compartment"
}

# tflint-ignore: terraform_unused_declarations
output "vcn" {
  value       = oci_core_vcn.vcn
  description = "The created VCN"
}

# tflint-ignore: terraform_unused_declarations
output "private_subnet" {
  value       = oci_core_subnet.private_subnet
  description = "The created private subnet"
}

# tflint-ignore: terraform_unused_declarations
output "public_subnet" {
  value       = oci_core_subnet.public_subnet
  description = "The created public subnet"
}

output "images" {
  value       = data.oci_core_images.oke_worker_images
  description = "Available compute instances"
}

output "network_compartment" {
  value       = local.compartment_id
  description = "The network compartment (OCID)"
}


# tflint-ignore: terraform_unused_declarations
output "ad" {
  value       = data.oci_identity_availability_domains.oci_identity_availability_domain
  description = "AD"
}
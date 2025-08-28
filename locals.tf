locals {
  # Determine compartment ID with validation
  compartment_id = (
    var.existing_compartment != "" ? 
    var.existing_compartment : 
    (length(oci_identity_compartment.network_compartment) > 0 ? oci_identity_compartment.network_compartment[0].id : var.compartment_id)
  )
}
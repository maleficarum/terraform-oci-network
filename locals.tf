locals {
  # Determine compartment ID with validation
  compartment_id = (
    var.existing_compartment != "" ?
    var.existing_compartment :
    (length(oci_identity_compartment.network_compartment) > 0 ? oci_identity_compartment.network_compartment[0].id : var.compartment_id)
  )
  # security_list_ids_by_subnet_name = {
  #   for sl in var.private_security_rules :
  #   sl.subnetwork_name => oci_core_security_list.private_security_list[index(var.private_security_rules, sl)].id
  # }
}
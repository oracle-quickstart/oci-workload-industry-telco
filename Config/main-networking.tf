# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "terraform_oci_networking_flannel" {
  count = var.cni_type == "flannel" ? 1 : 0
  source                = "github.com/oci-landing-zones/terraform-oci-modules-networking.git?ref=release-0.6.7"
  network_configuration = local.network_configuration_flannel
}
module "terraform_oci_networking_native" {
  count = var.cni_type == "native" ? 1 : 0 
  source                = "github.com/oci-landing-zones/terraform-oci-modules-networking.git?ref=release-0.6.7"
  network_configuration = local.network_configuration_native
}


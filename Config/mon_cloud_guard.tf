# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
  cloud_guard_configuration = {
  reporting_region = var.cloud_guard_reporting_region != null ? var.cloud_guard_reporting_region : local.regions_map[local.home_region_key]
  
  targets = {
    CLOUD-GUARD-TARGET-1 = {
      name = local.custom_target_name
      resource_id = var.cloud_guard_reporting_region != null ? var.cloud_guard_reporting_region : local.regions_map[local.home_region_key]
    }  

  }
}
}
locals {

  #-- Custom target name
  custom_target_name = null

}

module "lz_cloud_guard" {
  count                 = var.enable_cloud_guard ? 1 : 0
  depends_on            = [null_resource.wait_on_services_policy]
  source = "github.com/oci-landing-zones/terraform-oci-modules-security/cloud-guard"
  cloud_guard_configuration = local.cloud_guard_configuration
  tenancy_ocid = var.tenancy_ocid
  enable_output = true
}


# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
  security_zones_configuration = {
  tenancy_ocid     = var.tenancy_ocid
  reporting_region = var.cloud_guard_reporting_region != null ? var.cloud_guard_reporting_region : local.regions_map[local.home_region_key]
  
  security_zones = {
    SECURITY-ZONE = {
      name = "security-zone"
      compartment_id = local.security_compartment_id
      recipe_key = "CIS-L1-RECIPE"
    }  
  }

  recipes = {
    CIS-L1-RECIPE = {
      name = "security-zone-cis-level-1-recipe"
      description = "CIS Level 1 recipe"
      compartment_id = local.security_compartment_id
      cis_level = "1"
    }
    CIS-L2-RECIPE = {
      name = "security-zone-cis-level-2-recipe"
      description = "CIS Level 2 recipe"
      compartment_id = local.security_compartment_id
      cis_level = "2"
    }
  }
}
}


module "lz_security_zones" {
  count                  = var.enable_security_zones ? 1 : 0
  depends_on = [
    module.lz_compartments
  ]
    source = "github.com/oci-landing-zones/terraform-oci-modules-security//security-zones?ref=release-0.1.4"
  security_zones_configuration = local.security_zones_configuration
}


# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

### Creates scanning recipes and targets. All Landing Zone compartments are targets.
locals {
  scanning_configuration = {
  default_compartment_id = local.security_compartment_id

  host_recipes = {
    HOST-RECIPE = {
      name = "host-scan-recipe"
      port_scan_level = var.vss_port_scan_level
      schedule_settings = {
        type = var.vss_scan_schedule
        day_of_week = var.vss_scan_day
      }
      agent_settings = {
        scan_level = var.vss_agent_scan_level
        cis_benchmark_scan_level = var.vss_agent_cis_benchmark_settings_scan_level
      }
      file_scan_settings = {
        enable = var.vss_enable_file_scan
        folders_to_scan = var.vss_folders_to_scan
      }
    }
  }

  host_targets = {
    HOST-TARGET = {
      name = "host-scan-target"
      target_compartment_id = local.enclosing_compartment_id
      host_recipe_id = "HOST-RECIPE" # this is a reference to the recipe defined in host_recipes attribute.
    }
  }

  container_recipes = {
    CONTAINER-RECIPE = {
      name = "container-scan-recipe"
    }
  }

  container_targets = {
    CONTAINER-TARGET = {
      name = "container-scan-target"
      target_registry = {
        compartment_id = local.enclosing_compartment_id
      }
      container_recipe_id = "CONTAINER-RECIPE" # this is a reference to the recipe defined in container_recipes attribute.
    }
  }
}
}


module "lz_scanning" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-security//vss?ref=release-0.1.5-rms"
  depends_on = [null_resource.wait_on_services_policy]
  count      = var.vss_create ? 1 : 0
  scanning_configuration = local.scanning_configuration
}


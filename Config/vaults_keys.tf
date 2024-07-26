locals {
vaults_configuration = {
  default_compartment_id = local.security_compartment_id

  vaults = {
    VAULT = {
      name = "${var.service_label}-vault"
      # replica_region = var.region # available if your vault is a VPV (virtual private vault) and you want to replicate it to another region. for instance "us-phoenix-1", "us-ashburn-1"
    }
  }
  keys = {
    #BLOCK-VOLUME-KEY = {
      #name = "block-volume-key"
      #vault_key = "VAULT"
      #service_grantees = ["blockstorage"]
      #group_grantees = ["${var.service_label}-appdev-admin-group"]
    #}
  }
}
}
module "lz_vaults_keys" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-security//vaults?ref=release-0.1.4"

  providers = {
    oci = oci
    oci.home = oci.home
  }
  depends_on = [null_resource.wait_on_compartments]
  count  = var.cis_level == "2" ? 1 : 0
  vaults_configuration = local.vaults_configuration
}

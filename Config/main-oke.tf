# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

data "oci_containerengine_node_pool" "test_node_pool" {
    #Required
    node_pool_id = var.cni_type == "flannel" ? module.oke_flannel[0].node_pools["NODEPOOL1"].id : module.oke_native[0].node_pools["NODEPOOL1"].id
}

resource "local_file" "cloud_init_cpu_hp" {
  content = templatefile("${path.module}/files/cloud-init-wn_cpupinning.sh",
    {
      hp_size = var.hp_size
      cpu = var.cpu - 1
      cpu_pinning = var.cpu_pinning
      hp = var.hp
    }
  )
  filename = "${path.module}/files/cloud-init-wn_cpupinning.sh"
}
resource "local_file" "cloud_init_cpu_hp2" {
  count = local.nodepool_quantity 
  content = templatefile("${path.module}/files/cloud-init-wn_cpupinning.sh",
    {
      hp_size = var.hp_size2
      cpu = var.cpu2 - 1
      cpu_pinning = var.cpu_pinning2
      hp = var.hp2
    }
  )
  filename = "${path.module}/files/cloud-init-wn_cpupinning_${count.index}.sh"
}


module "oke_flannel" {
  depends_on = [module.terraform_oci_networking_flannel,module.terraform_oci_networking_native]
  source                 = "github.com/oci-landing-zones/terraform-oci-modules-workloads.git//cis-oke?ref=issue-523-rms"
  count = var.cni_type == "flannel" ? 1 : 0
  clusters_configuration = local.clusters_configuration_flannel
  workers_configuration  = local.workers_configuration_flannel
}
module "oke_native" {
  depends_on = [module.terraform_oci_networking_native,module.terraform_oci_networking_flannel]
  source                 = "github.com/oci-landing-zones/terraform-oci-modules-workloads.git//cis-oke?ref=issue-523-rms"
  count = var.cni_type == "native" ? 1 : 0
  clusters_configuration = local.clusters_configuration_native
  workers_configuration  = local.workers_configuration_native
}


module "operator_instance" {
  
  source = "github.com/oci-landing-zones/terraform-oci-modules-workloads.git//cis-compute-storage?ref=issue-523-rms"
  providers = {
    oci                                  = oci
    oci.block_volumes_replication_region = oci.block_volumes_replication_region
  }
  instances_configuration = local.instances_configuration
}

module "bastion" {
  depends_on = [module.oke_flannel,module.oke_native]
  source                 = "github.com/oci-landing-zones/terraform-oci-modules-security.git//bastion?ref=release-0.1.5-rms"
  bastions_configuration = local.bastions_configuration
  sessions_configuration = local.sessions_configuration
  instances_dependency   = module.operator_instance.instances
}

module "operator_dynamic_group" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-iam//dynamic-groups?ref=v0.2.0"
  providers  = { oci = oci.home }
  tenancy_ocid = var.tenancy_ocid
  dynamic_groups_configuration = local.dynamic_groups_configuration_oke
}

module "operator_policy" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-iam//policies?ref=v0.2.0"
  providers  = { oci = oci.home }
  tenancy_ocid = var.tenancy_ocid
  policies_configuration = local.policies_configuration_oke
} 

module "dns_dynamic_group" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-iam//dynamic-groups?ref=v0.2.0"
  providers  = { oci = oci.home }
  tenancy_ocid = var.tenancy_ocid
  dynamic_groups_configuration = local.dynamic_groups_configuration_dns
}

module "dns_policy" {
  depends_on = [module.oke_flannel,module.oke_native]
  source = "github.com/oci-landing-zones/terraform-oci-modules-iam//policies?ref=v0.2.0"
  providers  = { oci = oci.home }
  tenancy_ocid = var.tenancy_ocid
  policies_configuration = local.policies_configuration_dns
} 


data "oci_containerengine_cluster_kube_config" "kube_config" {
  for_each      = var.cni_type == "flannel" ? ( local.clusters_configuration_flannel != null   ? local.clusters_configuration_flannel["clusters"] : {}) : ( local.clusters_configuration_native != null   ? local.clusters_configuration_native["clusters"] : {})
  cluster_id    = var.cni_type == "flannel" ? module.oke_flannel[0].clusters[each.key].id : module.oke_native[0].clusters[each.key].id
  token_version = "2.0.0"
}


resource "null_resource" "add_kubeconfig1" { # This null resource is used to add the kube config on the Operator instance using the Bastion Session.
  for_each = local.sessions_configuration["sessions"]
  provisioner "local-exec" {
    command = "chmod 600 ${local.ssh_private_key}" 
  }

  provisioner "local-exec" {
    command = format("%s %s", replace(replace(replace(replace(module.bastion.sessions[each.key], "\"", "'"), "<privateKey>", local.ssh_private_key), "-o ProxyCommand", "-o StrictHostKeyChecking=no -o ProxyCommand"), "-W", "-o StrictHostKeyChecking=no -W"), "-y -x 'mkdir ~/.kube/'")
    
  }
  provisioner "local-exec" {
    command = format("%s %s", replace(replace(replace(replace(module.bastion.sessions[each.key], "\"", "'"), "<privateKey>", local.ssh_private_key), "-o ProxyCommand", "-o StrictHostKeyChecking=no -o ProxyCommand"), "-W", "-o StrictHostKeyChecking=no -W"), "-y -x 'echo \"${join(",", [for cluster in data.oci_containerengine_cluster_kube_config.kube_config : tostring(cluster.content)])}\" >> ~/.kube/config'")
  }
}

data "local_file" "existing" {
  filename = "${path.module}/install_kubectl.sh"
}
data "local_file" "olm" {
  filename = "${path.module}/files/install_olm.sh"
}




resource "null_resource" "install_kubectl" { # This null resource is used to install the kubectl and set the Operator instance OCI authentication to Instance Principal.
  for_each = local.sessions_configuration["sessions"]
  provisioner "local-exec" {
    command = format("%s %s", replace(replace(replace(replace(module.bastion.sessions[each.key], "\"", "'"), "<privateKey>", local.ssh_private_key), "-o ProxyCommand", "-o StrictHostKeyChecking=no -o ProxyCommand"), "-W", "-o StrictHostKeyChecking=no -W"), "-y -x '${data.local_file.existing.content}'")
  }
}
resource "null_resource" "add_multus" { 
  depends_on = [null_resource.install_kubectl,null_resource.add_kubeconfig1]
  count = var.multus ? 1 : 0
  provisioner "local-exec" {
    
    command = format("%s %s", replace(replace(replace(replace(module.bastion.sessions["SESSION-1"], "\"", "'"), "<privateKey>", local.ssh_private_key), "-o ProxyCommand", "-o StrictHostKeyChecking=no -o ProxyCommand"), "-W", "-o StrictHostKeyChecking=no -W"), "-y -x 'git clone https://github.com/k8snetworkplumbingwg/multus-cni.git && cd multus-cni && kubectl apply -f deployments/multus-daemonset.yml'") 
  }

}
resource "null_resource" "install_olm-1" { 
  depends_on = [null_resource.install_kubectl,null_resource.add_kubeconfig1]
  count = var.olm ? 1 : 0
  provisioner "local-exec" {
    command = format("%s %s", replace(replace(replace(replace(module.bastion.sessions["SESSION-1"], "\"", "'"), "<privateKey>", local.ssh_private_key), "-o ProxyCommand", "-o StrictHostKeyChecking=no -o ProxyCommand"), "-W", "-o StrictHostKeyChecking=no -W"), "-y -x '${data.local_file.olm.content}'")
  }
}
resource "null_resource" "install_olm-2" { 
  depends_on = [null_resource.install_olm-1]
  count = var.olm ? 1 : 0
  provisioner "local-exec" {
    command = format("%s %s", replace(replace(replace(replace(module.bastion.sessions["SESSION-1"], "\"", "'"), "<privateKey>", local.ssh_private_key), "-o ProxyCommand", "-o StrictHostKeyChecking=no -o ProxyCommand"), "-W", "-o StrictHostKeyChecking=no -W"), "-y -x 'operator-sdk olm install'")
  }
}


resource "null_resource" "install_metric_server" { 
  depends_on = [null_resource.install_kubectl,null_resource.add_kubeconfig1]
  count = var.metric_server ? 1 : 0
  provisioner "local-exec" {
    command = format("%s %s", replace(replace(replace(replace(module.bastion.sessions["SESSION-1"], "\"", "'"), "<privateKey>", local.ssh_private_key), "-o ProxyCommand", "-o StrictHostKeyChecking=no -o ProxyCommand"), "-W", "-o StrictHostKeyChecking=no -W"), "-y -x 'kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml'")
  }
}


module "Sriov_install" {
  depends_on = [null_resource.add_multus,module.oke_flannel,module.oke_native,null_resource.install_olm-1,null_resource.install_olm-2,null_resource.install_metric_server,null_resource.install_kubectl,null_resource.add_kubeconfig1]
  count = (var.sriov || var.sriov2)  ? local.nodepool_quantity+1:0
  source       = "./sriov_install"
  sriov  = count.index == 0 ? var.sriov : var.sriov2
  nodepool_id = var.cni_type == "flannel" ? module.oke_flannel[0].node_pools["NODEPOOL${count.index+1}"].id : module.oke_native[0].node_pools["NODEPOOL${count.index+1}"].id
  node_pool_size = count.index == 0 ? var.node_pool_size :  var.node_pool_size2
  session = module.bastion.sessions["SESSION-1"]
  ssh_private_key = local.ssh_private_key
  worker_id = local.worker_id
  worker_id_native = local.worker_id_native
  cni_type = var.cni_type
  nodepool_quantity = local.nodepool_quantity
}

resource "null_resource" "add_sriov-3" { 
  depends_on = [module.Sriov_install]
  count = (var.sriov || var.sriov2) ? 1  : 0
  provisioner "local-exec" {
    
    command = format("%s %s", replace(replace(replace(replace(module.bastion.sessions["SESSION-1"], "\"", "'"), "<privateKey>", local.ssh_private_key), "-o ProxyCommand", "-o StrictHostKeyChecking=no -o ProxyCommand"), "-W", "-o StrictHostKeyChecking=no -W"), "-y -x 'git clone https://github.com/k8snetworkplumbingwg/sriov-cni.git && cd sriov-cni && kubectl apply -f images/sriov-cni-daemonset.yaml'") 
  }

}

module "restart_nodes" {
  depends_on = [null_resource.add_multus,module.oke_flannel,module.oke_native,null_resource.install_olm-1,null_resource.install_olm-2,null_resource.install_metric_server,null_resource.install_kubectl,null_resource.add_kubeconfig1,null_resource.add_sriov-3]
  count = (var.cpu_pinning || var.cpu_pinning2)  ? local.nodepool_quantity+1:0
  source       = "./cpu_pinning_restart"
  cpu_pinning  = count.index == 0 ? var.cpu_pinning : var.cpu_pinning2
  nodepool_id = var.cni_type == "flannel" ? module.oke_flannel[0].node_pools["NODEPOOL${count.index+1}"].id : module.oke_native[0].node_pools["NODEPOOL${count.index+1}"].id
  node_pool_size = count.index == 0 ? var.node_pool_size :  var.node_pool_size2
  session = module.bastion.sessions["SESSION-1"]
  ssh_private_key = local.ssh_private_key
  nodepool_quantity = local.nodepool_quantity
}



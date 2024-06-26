locals {
  network_configuration_flannel = {
  default_compartment_id = local.network_compartment_id
  network_configuration_categories = {
    production = {
      category_freeform_tags = {
        "vision-sub-environment" = "prod"
      }
      vcns = {
        OKE-VCN-KEY = {
          display_name                     = var.VCN-name
          is_ipv6enabled                   = false
          is_oracle_gua_allocation_enabled = false
          cidr_blocks                      = var.VCN-CIDR
          dns_label                        = "vcnoke"
          block_nat_traffic                = false
          security_lists = {
            SECLIST-API-KEY = {
              display_name = "sl-api"
              egress_rules = []
              ingress_rules = [
                {
                  description = "Ingress ICMP for path discovery"
                  stateless   = false
                  protocol    = "ICMP"
                  src         = "0.0.0.0/0"
                  src_type    = "CIDR_BLOCK"
                  icmp_type   = 3
                  icmp_code   = 4
                }
              ]
            }
            SECLIST-WORKERS-KEY = {
              display_name = "sl-workers"
              egress_rules = []
              ingress_rules = [
                {
                  description = "Ingress ICMP for path discovery"
                  stateless   = false
                  protocol    = "ICMP"
                  src         = "0.0.0.0/0"
                  src_type    = "CIDR_BLOCK"
                  icmp_type   = 3
                  icmp_code   = 4
                }
              ]
            }
            SECLIST-OPERATOR-KEY = { # The TCP egress and ingress rules are to support communication within the subnet itself. A use case is when deploying a Bastion service endpoint for accessing the operator host.
              display_name = "sl-operator"
              egress_rules = [
                {
                  description  = "Allows outbound SSH traffic from operator subnet to hosts in the operator subnet, for Bastion service."
                  stateless    = false
                  protocol     = "TCP"
                  dst          = var.K8SOperatorSubnet-CIDR
                  dst_type     = "CIDR_BLOCK"
                  dst_port_min = 22
                  dst_port_max = 22
                },
              ],
              ingress_rules = [
                {
                  description = "Allows inbound ICMP traffic for path discovery."
                  stateless   = false
                  protocol    = "ICMP"
                  src         = "0.0.0.0/0"
                  src_type    = "CIDR_BLOCK"
                  icmp_type   = 3
                  icmp_code   = 4
                },
                {
                  description  = "Allows inbound SSH traffic from hosts in the operator subnet to the operator subnet, for Bastion service."
                  stateless    = false
                  protocol     = "TCP"
                  src          = var.K8SOperatorSubnet-CIDR
                  src_type     = "CIDR_BLOCK"
                  dst_port_min = 22
                  dst_port_max = 22
                }
              ]
            }
            SECLIST-SERVICES-KEY = {
              display_name = "sl-services"
              egress_rules = []
              ingress_rules = [
                {
                  description = "Ingress ICMP for path discovery"
                  stateless   = false
                  protocol    = "ICMP"
                  src         = "0.0.0.0/0"
                  src_type    = "CIDR_BLOCK"
                  icmp_type   = 3
                  icmp_code   = 4
                }
              ]
            }
			SECLIST-SIG-KEY = {
              display_name = "sl-signalling"
              egress_rules = []
              ingress_rules = [
                {
                  description = "Ingress ICMP for path discovery"
                  stateless   = false
                  protocol    = "ICMP"
                  src         = "0.0.0.0/0"
                  src_type    = "CIDR_BLOCK"
                  icmp_type   = 3
                  icmp_code   = 4
                }
              ]
            }
          }
          route_tables = {
            RT-API-KEY = {
              display_name = "rt-api"
              route_rules = {
                sgw-route = {
                  network_entity_key = "SGW-KEY"
                  description        = "Route for sgw"
                  destination        = "all-services"
                  destination_type   = "SERVICE_CIDR_BLOCK"
                }
                natgw-route = {
                  network_entity_key = "NATGW-KEY"
                  description        = "Route for internet access via NAT GW"
                  destination        = "0.0.0.0/0"
                  destination_type   = "CIDR_BLOCK"
                }
              }
            }
            RT-WORKERS-KEY = {
              display_name = "rt-workers"
              route_rules = {
                sgw-route = {
                  network_entity_key = "SGW-KEY"
                  description        = "Route for sgw"
                  destination        = "all-services"
                  destination_type   = "SERVICE_CIDR_BLOCK"
                },
                natgw-route = {
                  network_entity_key = "NATGW-KEY"
                  description        = "Route for internet access via NAT GW"
                  destination        = "0.0.0.0/0"
                  destination_type   = "CIDR_BLOCK"
                }
              }
            }
            RT-SERVICES-KEY = {
              display_name = "rt-services"
              route_rules = {
                igw-route = {
                  network_entity_key = "IGW-KEY"
                  description        = "Route for igw"
                  destination        = "0.0.0.0/0"
                  destination_type   = "CIDR_BLOCK"
                }
              }
            }
            RT-OPERATOR-KEY = {
              display_name = "rt-operator"
              route_rules = {
                sgw-route = {
                  network_entity_key = "SGW-KEY"
                  description        = "Route for sgw"
                  destination        = "all-services"
                  destination_type   = "SERVICE_CIDR_BLOCK"
                }
                natgw-route = {
                  network_entity_key = "NATGW-KEY"
                  description        = "Route for internet access via NAT GW"
                  destination        = "0.0.0.0/0"
                  destination_type   = "CIDR_BLOCK"
                }
              }
            }
			RT-SIG-KEY = {
              display_name = "rt-signalling"
              route_rules = {
                sgw-route = {
                  network_entity_key = "SGW-KEY"
                  description        = "Route for sgw"
                  destination        = "all-services"
                  destination_type   = "SERVICE_CIDR_BLOCK"
                }
              }
            }
          }
		  subnets = merge(
		  {
		  for i in range(0,var.subnet_number) : "Additional-subnet-key-${i}" => { 
              cidr_block                 = var.additionalsubnet-CIDR[i]
              dhcp_options_key           = "default_dhcp_options"
              display_name               = var.additionalsubnet_name[i]
              dns_label                  = "addsub${i}"
              ipv6cidr_blocks            = []
              prohibit_internet_ingress  = true
              prohibit_public_ip_on_vnic = true
              #route_table_key            = "RT-OPERATOR-KEY"
              #security_list_keys         = ["SECLIST-OPERATOR-KEY"]
          }
		  },
		  {
          API-SUBNET-KEY = {
              cidr_block                 = var.K8SAPIEndPointSubnet-CIDR
              dhcp_options_key           = "default_dhcp_options"
              display_name               = "sub-api"
              dns_label                  = "apisub"
              ipv6cidr_blocks            = []
              prohibit_internet_ingress  = true
              prohibit_public_ip_on_vnic = true
              route_table_key            = "RT-API-KEY"
              security_list_keys         = ["SECLIST-API-KEY"]
          }
          WORKERS-SUBNET-KEY = {
              cidr_block                 = var.K8SNodePoolSubnet-CIDR
              dhcp_options_key           = "default_dhcp_options"
              display_name               = "sub-workers"
              dns_label                  = "workerssub"
              ipv6cidr_blocks            = []
              prohibit_internet_ingress  = true
              prohibit_public_ip_on_vnic = true
              route_table_key            = "RT-WORKERS-KEY"
              security_list_keys         = ["SECLIST-WORKERS-KEY"]
            }
            SERVICES-SUBNET-KEY = {
              cidr_block                 = var.K8SLBSubnet-CIDR
              dhcp_options_key           = "default_dhcp_options"
              display_name               = "sub-services"
              dns_label                  = "servicessub"
              ipv6cidr_blocks            = []
              prohibit_internet_ingress  = false
              prohibit_public_ip_on_vnic = false
              route_table_key            = "RT-SERVICES-KEY"
              security_list_keys         = ["SECLIST-SERVICES-KEY"]
            }
            OPERATOR-SUBNET-KEY = {
              cidr_block                 = var.K8SOperatorSubnet-CIDR
              dhcp_options_key           = "default_dhcp_options"
              display_name               = "sub-operator"
              dns_label                  = "operatorsub"
              ipv6cidr_blocks            = []
              prohibit_internet_ingress  = true
              prohibit_public_ip_on_vnic = true
              route_table_key            = "RT-OPERATOR-KEY"
              security_list_keys         = ["SECLIST-OPERATOR-KEY"]
            }
			SIG-SUBNET-KEY = {
              cidr_block                 = var.K8SSignallingSubnet-CIDR
              dhcp_options_key           = "default_dhcp_options"
              display_name               = "sub-signalling"
              dns_label                  = "sigsub"
              ipv6cidr_blocks            = []
              prohibit_internet_ingress  = true
              prohibit_public_ip_on_vnic = true
              route_table_key            = "RT-SIG-KEY"
              security_list_keys         = ["SECLIST-SIG-KEY"]
            }
         }
         )
          
          network_security_groups = {
            NSG-API-KEY = {
              display_name = "nsg-api"
              egress_rules = {
                sgw_tcp = {
                  description = "Allow TCP egress from OKE control plane to OCI services"
                  stateless   = false
                  protocol    = "TCP"
                  dst         = "all-services"
                  dst_type    = "SERVICE_CIDR_BLOCK"
                }
                workers_healthcheck = {
                  description  = "Allow TCP egress from OKE control plane to Kubelet on worker nodes."
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-WORKERS-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 10250
                  dst_port_max = 10250
                }
                workers_12250 = {
                  description  = "Allow TCP egress from OKE control plane to worker node"
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-WORKERS-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 12250
                  dst_port_max = 12250
                }
                api_intercommunication = {
                  description  = "Allow TCP egress for Kubernetes control plane inter-communicatioN"
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-API-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 6443
                  dst_port_max = 6443
                }
                workers_icmp = {
                  description = "Allow ICMP egress for path discovery to worker nodes"
                  stateless   = false
                  protocol    = "ICMP"
                  dst         = "NSG-WORKERS-KEY"
                  dst_type    = "NETWORK_SECURITY_GROUP"
                  icmp_type   = 3
                  icmp_code   = 4
                }
              }
              ingress_rules = {
                api_intercommunication = {
                  description  = "Allow TCP ingress for Kubernetes control plane inter-communication."
                  stateless    = false
                  protocol     = "TCP"
                  src          = "NSG-API-KEY"
                  src_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 6443
                  dst_port_max = 6443
                }
                operator_client_access = {
                  description  = "Operator access to Kubernetes API endpoint"
                  stateless    = false
                  protocol     = "TCP"
                  src          = "NSG-OPERATOR-KEY"
                  src_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 6443
                  dst_port_max = 6443
                }
                workers_tcp_6443 = {
                  description  = "Allow TCP ingress to kube-apiserver from worker nodes"
                  stateless    = false
                  protocol     = "TCP"
                  src          = "NSG-WORKERS-KEY"
                  src_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 6443
                  dst_port_max = 6443
                }
                workers_tcp_10250 = {
                  description  = "Allow TCP ingress to OKE control plane from worker nodes"
                  stateless    = false
                  protocol     = "TCP"
                  src          = "NSG-WORKERS-KEY"
                  src_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 10250
                  dst_port_max = 10250
                }
                workers_tcp_12250 = {
                  description  = "Allow TCP ingress to OKE control plane from worker nodes"
                  stateless    = false
                  protocol     = "TCP"
                  src          = "NSG-WORKERS-KEY"
                  src_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 12250
                  dst_port_max = 12250
                }
                workers_icmp = {
                  description = "Allow ICMP ingress for path discovery from worker nodes."
                  stateless   = false
                  protocol    = "ICMP"
                  src         = "NSG-WORKERS-KEY"
                  src_type    = "NETWORK_SECURITY_GROUP"
                  icmp_type   = 3
                  icmp_code   = 4
                }
              }
            }
            NSG-WORKERS-KEY = {
              display_name = "nsg-workers"
              egress_rules = {
                workers_all = {
                  description = "Allow ALL egress from workers to other workers."
                  stateless   = false
                  protocol    = "ALL"
                  dst         = "NSG-WORKERS-KEY"
                  dst_type    = "NETWORK_SECURITY_GROUP"
                }
                sgw_tcp = {
                  description = "Allow TCP egress from workers to OCI Services."
                  stateless   = false
                  protocol    = "TCP"
                  dst         = "all-services"
                  dst_type    = "SERVICE_CIDR_BLOCK"
                }
                api_tcp_6443 = {
                  description  = "Allow TCP egress from workers to Kubernetes API server."
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-API-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 6443
                  dst_port_max = 6443
                }
                api_tcp_10250 = {
                  description  = "Allow TCP ingress to workers for health check from OKE control plane."
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-API-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 10250
                  dst_port_max = 10250
                }
                api_tcp_12250 = {
                  description  = "Allow TCP egress from workers to OKE control plane."
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-API-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 12250
                  dst_port_max = 12250
                }
                anywhere_icmp = {
                  description = "Path Discovery."
                  stateless   = false
                  protocol    = "ICMP"
                  dst         = "0.0.0.0/0"
                  dst_type    = "CIDR_BLOCK"
                  icmp_type   = 3
                  icmp_code   = 4
                }
                anywhere_tcp = {
                  description = "(optional) Allow worker nodes to communicate with internet."
                  stateless   = false
                  protocol    = "TCP"
                  dst         = "0.0.0.0/0"
                  dst_type    = "CIDR_BLOCK"
                }
              }

              ingress_rules = {
                workers_all = {
                  description = "Allow ALL ingress to workers from other workers."
                  stateless   = false
                  protocol    = "ALL"
                  src         = "NSG-WORKERS-KEY"
                  src_type    = "NETWORK_SECURITY_GROUP"
                }
                api_all = {
                  description = "Allow ALL ingress to workers from Kubernetes control plane for webhooks served by workers."
                  stateless   = false
                  protocol    = "ALL"
                  src         = "NSG-API-KEY"
                  src_type    = "NETWORK_SECURITY_GROUP"
                }
                lb_tcp_10256 = {
                  description  = "Allow TCP ingress to workers for health check from public load balancers"
                  stateless    = false
                  protocol     = "TCP"
                  src          = "NSG-SERVICES-KEY"
                  src_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 10256
                  dst_port_max = 10256
                }
                lb_tcp = {
                  description  = "Allow TCP ingress to workers from public load balancers"
                  stateless    = false
                  protocol     = "TCP"
                  src          = "NSG-SERVICES-KEY"
                  src_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 30000
                  dst_port_max = 32767
                }
                anywhere_icmp = {
                  description = "Allow ICMP ingress to workers for path discovery."
                  stateless   = false
                  protocol    = "ICMP"
                  src         = "0.0.0.0/0"
                  src_type    = "CIDR_BLOCK"
                  icmp_type   = 3
                  icmp_code   = 4
                }
                operator_ssh_access = {
                  description  = "Operator ssh access to workers"
                  stateless    = false
                  protocol     = "TCP"
                  src          = "NSG-OPERATOR-KEY"
                  src_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 22
                  dst_port_max = 22
                }
              }
            }
            NSG-SERVICES-KEY = {
              display_name = "nsg-services"
              egress_rules = {
                workers_traffic = {
                  description  = "Allow TCP egress from public load balancers to workers nodes for NodePort traffic"
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-WORKERS-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 30000
                  dst_port_max = 32767
                }
                workers_tcp_10256 = {
                  description  = "Allow TCP egress from public load balancers to worker nodes for health checks."
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-WORKERS-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 10256
                  dst_port_max = 10256
                }
                lb_workers_icmp = {
                  description = "Allow ICMP egress from public load balancers to worker nodes for path discovery."
                  stateless   = false
                  protocol    = "ICMP"
                  dst         = "NSG-WORKERS-KEY"
                  dst_type    = "NETWORK_SECURITY_GROUP"
                  icmp_type   = 3
                  icmp_code   = 4
                }
              }
              ingress_rules = {
                tcp_443 = {
                  description  = "Allow inbound traffic to Load Balancer."
                  stateless    = false
                  protocol     = "TCP"
                  src          = "0.0.0.0/0"
                  src_type     = "CIDR_BLOCK"
                  dst_port_min = 443
                  dst_port_max = 443
                }
              }
            }
            NSG-OPERATOR-KEY = {
              display_name = "nsg-operator"
              egress_rules = {
                sgw-tcp = {
                  description = "Allows TCP outbound traffic from operator subnet to OCI Services Network (OSN)."
                  stateless   = false
                  protocol    = "TCP"
                  dst         = "all-services"
                  dst_type    = "SERVICE_CIDR_BLOCK"
                }
                api-tcp = {
                  description  = "Allows TCP outbound traffic from operator subnet to Kubernetes API server, for OKE management."
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-API-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 6443
                  dst_port_max = 6443
                }
                anywhere-tcp = {
                  description = "Allows TCP egress from operator subnet to everywhere else."
                  stateless   = false
                  protocol    = "TCP"
                  dst         = "0.0.0.0/0"
                  dst_type    = "CIDR_BLOCK"
                }
              }
            }
			NSG-SIG-KEY = {
              display_name = "nsg-signalling"
              egress_rules = {
                sgw-tcp = {
                  description = "Allows TCP outbound traffic from signalling subnet to OCI Services Network (OSN)."
                  stateless   = false
                  protocol    = "TCP"
                  dst         = "all-services"
                  dst_type    = "SERVICE_CIDR_BLOCK"
                }
                api-tcp = {
                  description  = "Allows TCP outbound traffic from signalling subnet to Kubernetes API server, for OKE management."
                  stateless    = false
                  protocol     = "TCP"
                  dst          = "NSG-API-KEY"
                  dst_type     = "NETWORK_SECURITY_GROUP"
                  dst_port_min = 6443
                  dst_port_max = 6443
                }
              }
            }
          }
          vcn_specific_gateways = {
            internet_gateways = {
              IGW-KEY = {
                enabled      = true
                display_name = "igw-prod-vcn"
              }
            }
            nat_gateways = {
              NATGW-KEY = {
                block_traffic = false
                display_name  = "natgw-prod-vcn"
              }
            }
            service_gateways = {
              SGW-KEY = {
                display_name = "sgw-prod-vcn"
                services     = "all-services"
              }
            }
          }
		  dns_resolver = {
            display_name = var.VCN-name
            attached_views = {
              DNS_VIEW_1 = {
                display_name = var.VCN-name
                dns_zones = {
                  DNS_ZONE_1 = {
                    name      = var.zone_name
                    zone_type = "PRIMARY"
                    scope     = "PRIVATE"
                  }
           
                }
              }
            }
		  }
        }
      }
    }
  }
}

}

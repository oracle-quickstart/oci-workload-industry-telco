# Oracle Telco Landing Zone Quick Start Template
![Landing_Zone_Logo](images/landing%20zone_300.png)
## Table of Contents
1. [Overview](#overview)
1. [Features](#features)
1. [Architecture](#architecture)
    1. [IAM](#arch-iam)
    1. [Security](#arch-security)
    1. [Network](#arch-networking)
    1. [Workload](#arch-workload)
1. [Deployment Guide](DEPLOYMENT.md)
1. [Blog Posts](https://blogs.oracle.com/cloud-infrastructure/post/introducing-oci-telco-landing-zone)
1. [Feedback](#feedback)

## <a name="overview"></a>Overview
The Oracle Telco Landing Zone (referred to as the Landing Zone in the rest of this document) template deploys a standardized environment specially designed for telecom workloads in an Oracle Cloud Infrastructure (OCI) tenancy that helps telecom service providers to onboard and migrate their on-prem telco workloads (such as cloud-native 4G and 5G network functions and applications) onto OCI.

The Landing Zone is based off of the CIS OCI Landing Zone and utilizes other OCI Landing Zone modules for networking, security, and workloads as a reference. The Landing Zone deploys the following resources:

- Identity and Access Management: compartment structure, policies, groups, dynamic groups, identity domains.
- Network: A VCN with the required resources and the appropriate configuration needed for deploying an OKE cluster.
- Security: security services such as Cloud Guard, Vulnerability Scanning, Security Zones, Bastion Service, and Vaults.
- Workload: An Oracle Cloud Infrastructure Container Engine for Kubernetes (OKE) cluster, which can be configured according to the specific workloads that will be executed on top.
  
## <a name="features"></a>Features

This reference implementation is designed to support telco workloads on OCI, combined with the recommendations of CIS Foundations Benchmark for OCI and OCI architecture best practices. The  main differentiator of this landing zone is that it not only deploys the Identity and Management, Networking, and Security resources, but it also deploys workloads (OKE) required to onboard 4G/5G network functions. Furthermore, the OKE cluster deployed by the Landing Zone has been specially designed and customized to support both control plane and data plane workloads on OCI.

The key features of the Landing Zone are listed below:
- Deployment of different subnets for traffic segregation (signaling, OAM, replication, etc.), that is usually required for 4G and 5G telco workloads. These subnets can be used with the OKE Cluster as load balancer subnets or worker node subnets.
- Deployment of an OKE cluster, which can be customized according to each customer's need (compute shapes, CNI, Kubernetes version, type of cluster, etc.)
- Deployment of open-source projects usually required for telco workloads:
    - Multus
    - Metrics Server
    - Operator Lifecycle Manager (OLM)
- Single root input/output virtualization (SR-IOV)
- CPU Pinning
- Huge Pages
- Cloud Guard
- Vulnerability Scanning
  
## <a name="architecture"></a>Architecture

 The diagram below shows services and resources that are deployed as a part of this Landing Zone:

![Architecture_](images/oci_telco_landing_zone_baseline.png)

 ### <a name="arch-iam"></a>IAM Module
 This Identity and Access (IAM) module deploys the following resources:
 - Compartments
 - Policies
 - Groups
 - Dynamic groups
 - Identity Domains

 #### <a name="arch-iam-comp"></a>Compartments
 The Landing Zone template creates the following compartments in the tenancy root compartment or under an enclosing compartment:
 - Network compartment: for all networking resources.
 - Security Compartment: for all security-related services.
 - Workload compartment: for workload-related resources, including OCI Container Engine for Kubernetes (OKE), Compute, Storage, operator host, and additional open-source applications installed on OKE. 
 - Enclosing compartment: a compartment at any level in the compartment hierarchy to hold the above compartments. 

The compartment design reflects a basic functional structure observed across different organizations, where telco workloads are typically split among networking and telco workload admin teams. Each compartment is assigned an admin group, with enough permissions to perform its duties. The provided permissions lists are not exhaustive and are expected to be appended with new statements as new resources are brought into the Terraform template.

 #### <a name="arch-iam-grp"></a>Groups
The Landing Zone deploys the following groups:
- storage-admin-group: group for storage services management.
- cred-admin-group: group for managing user credentials in the tenancy.
- iam-admin-group: group for managing IAM resources in the tenancy.
- cost-admin-group: group for Cost management.
- appdev-admin-group: group for managing app development or workload related services
- database-admin-group: group for managing databases.
- network-admin-group: group for network management.
- announcement-reader-group: group for reading Console announcements.
- auditor-group: group for auditing the tenancy.
- security-admin-group: group for security services management.
 
 #### <a name="arch-iam-dyngrp"></a>Dynamic Groups
The Landing Zone deploys the following dynamic groups:
- appdev-fun-dynamic-group: dynamic group for application functions execution.
- sec-fun-dynamic-group: dynamic group for security functions execution.
- database-kms-dynamic-group: dynamic group for databases accessing Key Management service (aka Vault service).
- oke-operator-dynamic-group: dynamic group for the OKE operator.
- appdev-computeagent-dynamic-group: dynamic group for Compute Agent plugin execution.
- dns-dynamic-group: dynamic group for DNS zone.

 #### <a name="arch-iam-pol"></a>Policies
 The Landing Zone deploys the following policies:
 - oke-clusters-policy: Landing Zone policy for OKE clusters. It allows OKE clusters to use Native Pod Networking (NPN) and to use network resources in the Network compartment.
 - network-admin-policy: Landing Zone policy for network-admin-group group to manage network related services.
 - database-dynamic_group-policy: Landing Zone policy for database-kms-dynamic-group group to use Vault service.
 - database-admin-policy: Landing Zone policy for database-admin-group group to manage database related resources.
 - compute-agent-policy: Landing Zone policy for appdev-computeagent-dynamic-group group to manage compute agent related services.
 - appdev-admin-policy: Landing Zone policy for appdev-admin-group group to manage app development related services.
 - iam-admin-policy: Landing Zone policy for iam-admin-group group to manage IAM resources in Landing Zone enclosing compartment (compartment Telco_LZ).
 - storage-admin-policy: Landing Zone policy for storage-admin-group group to manage storage resources.\
 - security-admin-policy: Landing Zone policy for security-admin-group group to manage security related services in Landing Zone enclosing compartment (compartment Telco_LZ).

 ### <a name="arch-security"></a>Security Module
 This module contains modules for security services that help customers align their OCI implementations with the CIS (Center for Internet Security) OCI Foundations Benchmark recommendations.
 
 The Landing Zone can deploy the following services:
  - Bastion Service: this is a module that manages bastions and bastion sessions in OCI. The OCI Bastion service provides restricted and time-limited access to target resources that do not have public endpoints. Bastions let authorized users connect from specific IP addresses to target resources using Secure Shell (SSH) sessions. When connected, users can interact with the target resource by using any software or protocol supported by SSH.
 - Security Zones: OCI Security Zones let you be confident that OCI resources, including Compute, Networking, Object Storage, Block Volume and Database resources, comply with your security policies. Security zones are part of the Cloud Guard family, but its controls are preventative.
 - Cloud Guard: this module manages Cloud Guard service settings in Oracle Cloud Infrastructure (OCI) based on a single configuration object. OCI Cloud Guard helps customers monitor, identify, achieve, and maintain a strong security posture on Oracle Cloud. Use the service to examine your OCI resources for security weaknesses related to configuration and your OCI operators and users for risky activities. Upon detection, Cloud Guard can suggest, assist, or take corrective actions, based on your configuration.
 - Vulnerability Scanning: this module manages vulnerability scanning settings in Oracle Cloud Infrastructure (OCI) based on a single configuration object. OCI Vulnerability Scanning Service (VSS) helps improve a tenancy security posture by routinely checking hosts and container images for potential vulnerabilities.
 
 ### <a name="arch-networking"></a>Networking Module
 This module provisions a network architecture suitable for OKE within one a single Virtual Cloud Network (VCN)s. The following subnets are created:
 - OAM Subnet: public or private subnet for load balancer services related to OAM;
 - Signaling Subnet: public or private subnet for load balancer services related to O4G or 5G signaling traffic;
 - OKE K8s API Subnet: private subnet for the OKE Kubernetes API endpoint;
 - Worker Node Subnet: private subnet used for the OKE worker nodes;
 - Operator subnet: this subnet (private) is used for the operator instance and the bastion service.

The Landing Zone allows additional subnets to be deployed, if needed. These additional subnets can be used for worker node subnets, load balancers, compute instances, or any other OCI resource that may be needed.
 
The following gateways are deployed with the VCN:
- Service gateway: provides private and secure access to multiple Oracle Cloud services simultaneously from within a virtual cloud network (VCN) or on-premises network via a single gateway without traversing the internet.
- NAT gateway: provides internet access to resources that are behind a private subnet, without exposing them to incoming internet connections.
- Internet gateway (optional): provides a path for network traffic between VCN & Internet.
- Dynamic routing gateway (DRG) for on-premises connectivity: provides a path for traffic between on-premises networks and virtual cloud networks (VCNs).


 ### <a name="arch-workload"></a>Workload Module
This module manages OKE clusters and its node pools on OCI. OKE is a managed service that lets you deploy and manage containerized applications in the cloud.  It handles the heavy lifting of setting up and maintaining a Kubernetes cluster, so you can focus on building and deploying your apps. OKE offers features like automatic scaling, self-healing capabilities, and built-in security for your containerized workloads. It also integrates seamlessly with other Oracle Cloud services, making it a powerful tool for building and running cloud-native applications.

The Landing Zone deploys a basic OKE cluster and an Operator instance, which is configured by the Landing Zone to connect to the OKE cluster using kubectl.
The OKE cluster deployed by the Landing Zone can be configured according to the following parameters:

- Kubernetes Version
- Node Pool Configuration: compute shape (AMD/Intel/ARM), network, worker node OS, etc.
- Additional Node Pool: an additional node pool can be deployed, if there are different requirements for the workloads (e.g: compute shape, CPU pinning/, huge pages, SR-IOV, etc.)
- Additional Node Pool Configuration: compute shape (AMD/Intel/ARM), network, worker node OS, etc.
- Telco-specific features:
    - Single root input/output virtualization (SR-IOV): is a standard for a type of PCI device assignment that can share a single device to multiple virtual machines. SR-IOV improves device performance for virtual machines and is usually required for low-latency workloads, data plane telco workloads, video streaming, real-time applications, and large or clustered databases. For more information: https://github.com/k8snetworkplumbingwg/sriov-cni
    - Data Plane Development Kit (DPDK) Support: a framework comprised of various userspace libraries and drivers for fast packet processing.
    - Multus: a container network interface (CNI) plugin for Kubernetes that enables attaching multiple network interfaces to pods. If checked, the latest version of Multus will be installed in the OKE cluster. For more information: https://github.com/k8snetworkplumbingwg/multus-cni
    - Metrics Server: a scalable, efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines. Metrics Server is used by cloud-native network functions for horizontal pod autoscaling on OKE. For more information: https://github.com/kubernetes-sigs/metrics-server
    - Operator Lifecycle Manager (OLM): extends Kubernetes to provide a declarative way to install, manage, and upgrade Operators and their dependencies in a cluster. For more information: https://olm.operatorframework.io/
    - CPU Pinning: a tool that, in Kubernetes, binds a thread or process to a specific CPU core, preventing it from running on any other core.
    - Huge Pages: a memory management technique to improve performance by using larger memory blocks than the default page size. Huge Pages helps reduce the pressure on the Translation Lookaside Buffer (TLB) and lower the overhead of managing memory in systems with large amounts of RAM.

## <a name="dep-guide"></a>Deployment
The Landing Zone can be deployed using Oracle Resource Manager.

To deploy the Landing Zone, click the following button:
[![Deploy_To_OCI](images/DeployToOCI.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oci-landing-zones/oci-workload-industry-telco/archive/main.zip)<br>
*If you are logged into your OCI tenancy in the Commercial Realm (OC1), the button will take you directly to OCI Resource Manager where you can proceed to deploy. If you are not logged, the button takes you to Oracle Cloud initial page where you must enter your tenancy name and login to OCI.*
<br>

For instructions on how to deploy the landing zone: [Deployment](DEPLOYMENT.md)

## <a name="documentation"></a>Documentation

- [Strong Security Posture Monitoring with Cloud Guard](https://www.ateam-oracle.com/cloud-guard-support-in-cis-oci-landing-zone)
- [Logging Consolidation with Service Connector Hub](https://www.ateam-oracle.com/security-log-consolidation-in-cis-oci-landing-zone)
- [Vulnerability Scanning in CIS OCI Landing Zone](https://www.ateam-oracle.com/vulnerability-scanning-in-cis-oci-landing-zone)
- [Operational Monitoring and Alerting in the CIS Landing Zone](https://www.ateam-oracle.com/operational-monitoring-and-alerting-in-the-cis-landing-zone)
- [The Center for Internet Security Oracle Cloud Infrastructure Foundations Benchmark 1.2 Release update](https://www.ateam-oracle.com/post/the-center-for-internet-security-oracle-cloud-infrastructure-foundations-benchmark-12-release-update)

## <a name="modules"></a>CIS OCI Foundations Benchmark Modules Collection

This repository uses a broader collection of repositories containing modules that help customers align their OCI implementations with the CIS OCI Foundations Benchmark recommendations:
- [Identity & Access Management](https://github.com/oci-landing-zones/terraform-oci-modules-iam)
- [Networking](https://github.com/oci-landing-zones/terraform-oci-modules-networking)
- [Governance](https://github.com/oci-landing-zones/terraform-oci-modules-governance)
- [Security](https://github.com/oci-landing-zones/terraform-oci-modules-security)
- [Observability & Monitoring](https://github.com/oci-landing-zones/terraform-oci-modules-observability)
- [Secure Workloads](https://github.com/oci-landing-zones/terraform-oci-modules-workloads)

The modules in this collection are designed for flexibility, are straightforward to use, and enforce CIS OCI Foundations Benchmark recommendations when possible.

Using these modules does not require a user extensive knowledge of Terraform or OCI resource types usage. Users declare a JSON object describing the OCI resources according to each module’s specification and minimal Terraform code to invoke the modules. The modules generate outputs that can be consumed by other modules as inputs, allowing for the creation of independently managed operational stacks to automate your entire OCI infrastructure.


## <a name="feedback"></a>Feedback
We welcome your feedback. To post feedback, submit feature ideas or report bugs, please use the Issues section on this repository.  

* **Support for free tier tenancies**
    * Deploying in a free tier tenancy is not supported at this time as there are some services that are not available. If you want to try the Landing Zone, please upgrade your account to a pay-go. 

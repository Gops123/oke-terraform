# OKE Terraform Infrastructure


# Provider configuration
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Data sources
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "current_region" {
  filter {
    name   = "name"
    values = [var.region]
  }
}

locals {
  common_freeform_tags = merge(
    var.freeform_tags,
    {
      "Created-By" = "Terraform"
      "Project"    = var.project_name
      "Environment" = var.environment
      "Region"     = var.region
    }
  )
  
  name_prefix = "${var.project_name}-${var.environment}"
  availability_domains = data.oci_identity_availability_domains.ads.availability_domains != null ? data.oci_identity_availability_domains.ads.availability_domains[*].name : []
  computed_worker_kubernetes_version = var.worker_kubernetes_version != "" ? var.worker_kubernetes_version : var.kubernetes_version
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  compartment_id      = var.compartment_id
  display_name_prefix = local.name_prefix
  dns_label          = var.vcn_dns_label
  vcn_cidr_block = var.vcn_cidr_block
  
  k8s_api_endpoint_subnet_cidr = var.k8s_api_endpoint_subnet_cidr
  worker_nodes_subnet_cidr     = var.worker_nodes_subnet_cidr
  load_balancers_subnet_cidr   = var.load_balancers_subnet_cidr
  pod_network_subnet_cidr      = var.pod_network_subnet_cidr
  bastion_subnet_cidr          = var.bastion_subnet_cidr
  
  create_pod_network_subnet = var.create_pod_network_subnet
  create_bastion_subnet     = var.create_bastion_subnet
  
  load_balancer_ingress_ports = var.load_balancer_ingress_ports
  bastion_allowed_cidrs       = var.bastion_allowed_cidrs
  
  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

# OKE Cluster Module
module "oke_cluster" {
  source = "./modules/oke-cluster"
  
  depends_on = [module.networking]
  
  compartment_id      = var.compartment_id
  display_name_prefix = local.name_prefix
  
  vcn_id                     = module.networking.vcn_id
  api_endpoint_subnet_id     = module.networking.k8s_api_endpoint_subnet_id
  load_balancer_subnet_ids   = [module.networking.load_balancers_subnet_id]
  api_endpoint_nsg_ids       = var.api_endpoint_nsg_ids
  
  kubernetes_version      = var.kubernetes_version
  cluster_type           = var.cluster_type
  cni_type              = var.cni_type
  is_api_endpoint_public = var.is_api_endpoint_public
  
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr
  
  image_signing_enabled = var.image_signing_enabled
  image_signing_key_ids = var.image_signing_key_ids
  cluster_kms_key_id    = var.cluster_kms_key_id
  
  enable_kubernetes_dashboard = var.enable_kubernetes_dashboard
  enable_tiller               = var.enable_tiller
  enable_pod_security_policy  = var.enable_pod_security_policy
  
  pv_freeform_tags = merge(local.common_freeform_tags, { "Component" = "storage" })
  pv_defined_tags  = var.defined_tags
  lb_freeform_tags = merge(local.common_freeform_tags, { "Component" = "networking" })
  lb_defined_tags  = var.defined_tags
  
  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

# Node Pools Module
module "node_pools" {
  source = "./modules/node-pool"
  
  depends_on = [module.oke_cluster]
  
  compartment_id      = var.compartment_id
  display_name_prefix = local.name_prefix
  cluster_id         = module.oke_cluster.cluster_id
  kubernetes_version = local.computed_worker_kubernetes_version
  
  worker_subnet_id = module.networking.worker_nodes_subnet_id
  pod_subnet_ids   = var.create_pod_network_subnet ? [module.networking.pod_network_subnet_id] : null
  cni_type        = var.cni_type
  
  node_pools = var.node_pools
  
  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}


##############################################################################
# Basic OKE Example
# 
# This example creates a minimal OKE cluster with:
# - Basic networking setup
# - Single node pool
# - Development-friendly configuration
##############################################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
}

# Configure the OCI Provider
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Get the latest OKE worker node image
data "oci_containerengine_node_pool_option" "node_pool_options" {
  node_pool_option_id = "all"
}

locals {
  # Get the latest image for the region
  latest_image_id = [
    for image in data.oci_containerengine_node_pool_option.node_pool_options.sources :
    image.image_id if image.source_type == "IMAGE"
  ][0]
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  compartment_id      = var.compartment_id
  display_name_prefix = "basic-oke"
  dns_label          = "basicoke"
  
  # Simple network configuration
  vcn_cidr_block                = "10.0.0.0/16"
  k8s_api_endpoint_subnet_cidr = "10.0.0.0/30"
  worker_nodes_subnet_cidr     = "10.0.1.0/24"
  load_balancers_subnet_cidr   = "10.0.2.0/24"
  
  # Enable pod network subnet for VCN-Native CNI
  create_pod_network_subnet = true
  pod_network_subnet_cidr   = "10.0.4.0/24"
  
  # Optional bastion for debugging
  create_bastion_subnet = false
  
  freeform_tags = {
    Example = "basic-oke"
    Purpose = "demonstration"
  }
}

# OKE Cluster Module
module "oke_cluster" {
  source = "../../modules/oke-cluster"
  
  depends_on = [module.networking]
  
  compartment_id      = var.compartment_id
  display_name_prefix = "basic-oke"
  
  # Network configuration
  vcn_id                     = module.networking.vcn_id
  api_endpoint_subnet_id     = module.networking.k8s_api_endpoint_subnet_id
  load_balancer_subnet_ids   = [module.networking.load_balancers_subnet_id]
  
  # Basic cluster configuration
  kubernetes_version     = "v1.28.2"
  cluster_type          = "BASIC_CLUSTER"
  cni_type             = "OCI_VCN_IP_NATIVE"
  is_api_endpoint_public = true  # Easier for development
  
  # Enable dashboard for easier management
  enable_kubernetes_dashboard = true
  
  freeform_tags = {
    Example = "basic-oke"
    Purpose = "demonstration"
  }
}

# Node Pool Module
module "node_pools" {
  source = "../../modules/node-pool"
  
  depends_on = [module.oke_cluster]
  
  compartment_id      = var.compartment_id
  display_name_prefix = "basic-oke"
  cluster_id         = module.oke_cluster.cluster_id
  kubernetes_version = "v1.28.2"
  
  # Network configuration
  worker_subnet_id = module.networking.worker_nodes_subnet_id
  pod_subnet_ids   = [module.networking.pod_network_subnet_id]
  cni_type        = "OCI_VCN_IP_NATIVE"
  
  # Single node pool configuration
  node_pools = {
    default = {
      shape                = "VM.Standard.E4.Flex"
      image_id            = local.latest_image_id
      size                = 2
      availability_domains = slice(data.oci_identity_availability_domains.ads.availability_domains[*].name, 0, 2)
      
      boot_volume_size_gb = 50
      
      node_labels = {
        example = "basic-oke"
        pool    = "default"
      }
      
      shape_config = {
        memory_in_gbs = 16
        ocpus        = 2
      }
      
      node_cycling = {
        enabled = true
      }
    }
  }
  
  freeform_tags = {
    Example = "basic-oke"
    Purpose = "demonstration"
  }
}

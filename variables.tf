# OKE Infrastructure Variables

# Provider Configuration
variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}

variable "region" {
  description = "The OCI region name"
  type        = string
}

variable "compartment_id" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

# Project Configuration
variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Network Configuration
variable "vcn_dns_label" {
  description = "DNS label for the VCN"
  type        = string
}

variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "k8s_api_endpoint_subnet_cidr" {
  description = "CIDR block for Kubernetes API endpoint subnet"
  type        = string
  default     = "10.0.0.0/30"
}

variable "worker_nodes_subnet_cidr" {
  description = "CIDR block for worker nodes subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "load_balancers_subnet_cidr" {
  description = "CIDR block for load balancers subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "pod_network_subnet_cidr" {
  description = "CIDR block for pod network subnet (VCN-Native CNI)"
  type        = string
  default     = "10.0.4.0/24"
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for bastion subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# Optional Network Features
variable "create_pod_network_subnet" {
  description = "Whether to create a dedicated subnet for pod network (VCN-Native CNI)"
  type        = bool
  default     = true
}

variable "create_bastion_subnet" {
  description = "Whether to create a bastion subnet"
  type        = bool
  default     = false
}

variable "load_balancer_ingress_ports" {
  description = "Additional ports to allow ingress on load balancer subnet"
  type        = list(number)
  default     = [8080, 8443]
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# OKE Cluster Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for the control plane"
  type        = string
}

variable "worker_kubernetes_version" {
  description = "Kubernetes version for worker nodes (defaults to same as control plane)"
  type        = string
  default     = ""
}

variable "cluster_type" {
  description = "The type of cluster (BASIC_CLUSTER or ENHANCED_CLUSTER)"
  type        = string
  default     = "ENHANCED_CLUSTER"
}

variable "cni_type" {
  description = "The CNI type for the cluster (FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE)"
  type        = string
  default     = "OCI_VCN_IP_NATIVE"
}

variable "is_api_endpoint_public" {
  description = "Whether the Kubernetes API endpoint should be publicly accessible"
  type        = bool
  default     = false
}

variable "api_endpoint_nsg_ids" {
  description = "Network Security Group OCIDs for the API endpoint"
  type        = list(string)
  default     = []
}

# Network Configuration for Kubernetes
variable "pods_cidr" {
  description = "CIDR block for pods (CNI-assigned IP range)"
  type        = string
  default     = "10.244.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for services (ClusterIP services)"
  type        = string
  default     = "10.96.0.0/16"
}

# Security Configuration
variable "image_signing_enabled" {
  description = "Whether to enable image verification for the cluster"
  type        = bool
  default     = false
}

variable "image_signing_key_ids" {
  description = "KMS key OCIDs used for image signing verification"
  type        = list(string)
  default     = []
}

variable "cluster_kms_key_id" {
  description = "KMS key OCID for cluster encryption (optional)"
  type        = string
  default     = null
}

# Add-ons and Features
variable "enable_kubernetes_dashboard" {
  description = "Whether to enable the Kubernetes dashboard add-on"
  type        = bool
  default     = false
}

variable "enable_tiller" {
  description = "Whether to enable Tiller (Helm v2) - deprecated"
  type        = bool
  default     = false
}

variable "enable_pod_security_policy" {
  description = "Whether to enable Pod Security Policy admission controller"
  type        = bool
  default     = false
}

# Node Pool Configuration
variable "node_pools" {
  description = "Configuration for node pools"
  type = map(object({
    # Basic Configuration
    shape                = string
    image_id            = string
    size                = number
    availability_domains = list(string)
    
    # Optional Basic Configuration
    boot_volume_size_gb = optional(number, 50)
    ssh_public_key     = optional(string)
    
    # Node Labels
    node_labels = optional(map(string), {})
    
    # Shape Configuration (for flexible shapes)
    shape_config = optional(object({
      memory_in_gbs = optional(number)
      ocpus        = optional(number)
    }))
    
    # Security and Encryption
    pv_encryption_in_transit = optional(bool, false)
    kms_key_id              = optional(string)
    
    # Networking (VCN-Native CNI)
    max_pods_per_node = optional(number)
    pod_nsg_ids      = optional(list(string), [])
    
    # Node Management
    node_cycling = optional(object({
      enabled             = optional(bool, false)
      maximum_surge      = optional(string, "1")
      maximum_unavailable = optional(string, "0")
    }))
    
    node_eviction_settings = optional(object({
      eviction_grace_duration              = optional(string, "PT1H")
      is_force_delete_after_grace_duration = optional(bool, false)
    }))
    
    # Advanced Placement
    capacity_reservation_id = optional(string)
    fault_domains          = optional(list(string))
    
    # Cloud-init and metadata
    node_metadata = optional(map(string), {})
    
    # Tagging
    freeform_tags = optional(map(string), {})
    defined_tags  = optional(map(string), {})
  }))
}

# Tagging
variable "freeform_tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags to apply to all resources"
  type        = map(string)
  default     = {}
}
##############################################################################
# Node Pool Module Variables
##############################################################################

variable "compartment_id" {
  description = "The OCID of the compartment where node pools will be created"
  type        = string
  validation {
    condition     = can(regex("^ocid1\\.compartment\\.", var.compartment_id))
    error_message = "The compartment_id must be a valid OCI compartment OCID."
  }
}

variable "display_name_prefix" {
  description = "Prefix for node pool display names"
  type        = string
  validation {
    condition     = length(var.display_name_prefix) <= 50
    error_message = "Display name prefix must be 50 characters or less."
  }
}

variable "cluster_id" {
  description = "The OCID of the OKE cluster"
  type        = string
  validation {
    condition     = can(regex("^ocid1\\.cluster\\.", var.cluster_id))
    error_message = "The cluster_id must be a valid OCI cluster OCID."
  }
}

variable "kubernetes_version" {
  description = "The version of Kubernetes for worker nodes"
  type        = string
  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.kubernetes_version))
    error_message = "Kubernetes version must be in format vX.Y.Z (e.g., v1.28.2)."
  }
}

# Network Configuration
variable "worker_subnet_id" {
  description = "The OCID of the subnet for worker nodes"
  type        = string
  validation {
    condition     = can(regex("^ocid1\\.subnet\\.", var.worker_subnet_id))
    error_message = "The worker_subnet_id must be a valid OCI subnet OCID."
  }
}

variable "pod_subnet_ids" {
  description = "List of subnet OCIDs for pods (VCN-Native CNI only)"
  type        = list(string)
  default     = null
  validation {
    condition = var.pod_subnet_ids == null || alltrue([
      for subnet_id in var.pod_subnet_ids : can(regex("^ocid1\\.subnet\\.", subnet_id))
    ])
    error_message = "All pod_subnet_ids must be valid OCI subnet OCIDs."
  }
}

variable "cni_type" {
  description = "The CNI type used by the cluster (FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE)"
  type        = string
  default     = "OCI_VCN_IP_NATIVE"
  validation {
    condition     = contains(["FLANNEL_OVERLAY", "OCI_VCN_IP_NATIVE"], var.cni_type)
    error_message = "CNI type must be either FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE."
  }
}

# Node Pool Configuration
variable "node_pools" {
  description = "Map of node pool configurations"
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

  validation {
    condition = alltrue([
      for pool_name, pool_config in var.node_pools : 
      length(pool_config.availability_domains) > 0
    ])
    error_message = "Each node pool must specify at least one availability domain."
  }

  validation {
    condition = alltrue([
      for pool_name, pool_config in var.node_pools : 
      pool_config.size >= 0
    ])
    error_message = "Node pool size must be non-negative."
  }

  validation {
    condition = alltrue([
      for pool_name, pool_config in var.node_pools : 
      can(regex("^ocid1\\.image\\.", pool_config.image_id))
    ])
    error_message = "All image_ids must be valid OCI image OCIDs."
  }

  validation {
    condition = alltrue([
      for pool_name, pool_config in var.node_pools : 
      pool_config.boot_volume_size_gb >= 50
    ])
    error_message = "Boot volume size must be at least 50 GB."
  }
}

# Tagging
variable "freeform_tags" {
  description = "Freeform tags to apply to all node pools"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags to apply to all node pools"
  type        = map(string)
  default     = {}
}

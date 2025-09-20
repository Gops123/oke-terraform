##############################################################################
# OKE Cluster Module Variables
##############################################################################

variable "compartment_id" {
  description = "The OCID of the compartment where the cluster will be created"
  type        = string
  validation {
    condition     = can(regex("^ocid1\\.compartment\\.", var.compartment_id))
    error_message = "The compartment_id must be a valid OCI compartment OCID."
  }
}

variable "display_name_prefix" {
  description = "Prefix for resource display names"
  type        = string
  validation {
    condition     = length(var.display_name_prefix) <= 50
    error_message = "Display name prefix must be 50 characters or less."
  }
}

# Network Configuration
variable "vcn_id" {
  description = "The OCID of the VCN where the cluster will be created"
  type        = string
  validation {
    condition     = can(regex("^ocid1\\.vcn\\.", var.vcn_id))
    error_message = "The vcn_id must be a valid OCI VCN OCID."
  }
}

variable "api_endpoint_subnet_id" {
  description = "The OCID of the subnet for the Kubernetes API endpoint"
  type        = string
  validation {
    condition     = can(regex("^ocid1\\.subnet\\.", var.api_endpoint_subnet_id))
    error_message = "The api_endpoint_subnet_id must be a valid OCI subnet OCID."
  }
}

variable "load_balancer_subnet_ids" {
  description = "List of subnet OCIDs for load balancers"
  type        = list(string)
  validation {
    condition = alltrue([
      for subnet_id in var.load_balancer_subnet_ids : can(regex("^ocid1\\.subnet\\.", subnet_id))
    ])
    error_message = "All load_balancer_subnet_ids must be valid OCI subnet OCIDs."
  }
}

variable "api_endpoint_nsg_ids" {
  description = "List of Network Security Group OCIDs for the API endpoint"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for nsg_id in var.api_endpoint_nsg_ids : can(regex("^ocid1\\.networksecuritygroup\\.", nsg_id))
    ])
    error_message = "All api_endpoint_nsg_ids must be valid OCI NSG OCIDs."
  }
}

# Cluster Configuration
variable "kubernetes_version" {
  description = "The version of Kubernetes to use for the cluster"
  type        = string
  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.kubernetes_version))
    error_message = "Kubernetes version must be in format vX.Y.Z (e.g., v1.28.2)."
  }
}

variable "cluster_type" {
  description = "The type of cluster (BASIC_CLUSTER or ENHANCED_CLUSTER)"
  type        = string
  default     = "ENHANCED_CLUSTER"
  validation {
    condition     = contains(["BASIC_CLUSTER", "ENHANCED_CLUSTER"], var.cluster_type)
    error_message = "Cluster type must be either BASIC_CLUSTER or ENHANCED_CLUSTER."
  }
}

variable "cni_type" {
  description = "The CNI type for the cluster (FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE)"
  type        = string
  default     = "OCI_VCN_IP_NATIVE"
  validation {
    condition     = contains(["FLANNEL_OVERLAY", "OCI_VCN_IP_NATIVE"], var.cni_type)
    error_message = "CNI type must be either FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE."
  }
}

variable "is_api_endpoint_public" {
  description = "Whether the Kubernetes API endpoint should be publicly accessible"
  type        = bool
  default     = false
}

# Network Configuration
variable "pods_cidr" {
  description = "CIDR block for pods (CNI-assigned IP range)"
  type        = string
  default     = "10.244.0.0/16"
  validation {
    condition     = can(cidrhost(var.pods_cidr, 0))
    error_message = "Pods CIDR must be a valid IPv4 CIDR."
  }
}

variable "services_cidr" {
  description = "CIDR block for services (ClusterIP services)"
  type        = string
  default     = "10.96.0.0/16"
  validation {
    condition     = can(cidrhost(var.services_cidr, 0))
    error_message = "Services CIDR must be a valid IPv4 CIDR."
  }
}

# Add-ons and Features
variable "enable_kubernetes_dashboard" {
  description = "Whether to enable the Kubernetes dashboard add-on"
  type        = bool
  default     = false
}

variable "enable_tiller" {
  description = "Whether to enable Tiller (Helm v2) - deprecated, use Helm v3"
  type        = bool
  default     = false
}

variable "enable_pod_security_policy" {
  description = "Whether to enable Pod Security Policy admission controller"
  type        = bool
  default     = false
}

# Security Configuration
variable "image_signing_enabled" {
  description = "Whether to enable image verification for the cluster"
  type        = bool
  default     = false
}

variable "image_signing_key_ids" {
  description = "List of KMS key OCIDs used for image signing verification"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for key_id in var.image_signing_key_ids : can(regex("^ocid1\\.key\\.", key_id))
    ])
    error_message = "All image_signing_key_ids must be valid OCI KMS key OCIDs."
  }
}

variable "cluster_kms_key_id" {
  description = "The OCID of the KMS key for cluster encryption (optional)"
  type        = string
  default     = null
  validation {
    condition     = var.cluster_kms_key_id == null || can(regex("^ocid1\\.key\\.", var.cluster_kms_key_id))
    error_message = "The cluster_kms_key_id must be a valid OCI KMS key OCID or null."
  }
}

# Tagging for sub-resources
variable "pv_freeform_tags" {
  description = "Freeform tags to apply to persistent volumes created by the cluster"
  type        = map(string)
  default     = {}
}

variable "pv_defined_tags" {
  description = "Defined tags to apply to persistent volumes created by the cluster"
  type        = map(string)
  default     = {}
}

variable "lb_freeform_tags" {
  description = "Freeform tags to apply to load balancers created by the cluster"
  type        = map(string)
  default     = {}
}

variable "lb_defined_tags" {
  description = "Defined tags to apply to load balancers created by the cluster"
  type        = map(string)
  default     = {}
}

# General Tagging
variable "freeform_tags" {
  description = "Freeform tags to apply to the cluster"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags to apply to the cluster"
  type        = map(string)
  default     = {}
}

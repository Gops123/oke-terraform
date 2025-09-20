##############################################################################
# Networking Module Variables
##############################################################################

variable "compartment_id" {
  description = "The OCID of the compartment where networking resources will be created"
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

variable "dns_label" {
  description = "DNS label for the VCN (alphanumeric, max 15 characters)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,14}$", var.dns_label))
    error_message = "DNS label must start with a letter and contain only alphanumeric characters, max 15 characters."
  }
}

# VCN Configuration
variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vcn_cidr_block, 0))
    error_message = "VCN CIDR block must be a valid IPv4 CIDR."
  }
}

# Subnet CIDR Blocks
variable "k8s_api_endpoint_subnet_cidr" {
  description = "CIDR block for Kubernetes API endpoint subnet"
  type        = string
  default     = "10.0.0.0/30"
  validation {
    condition     = can(cidrhost(var.k8s_api_endpoint_subnet_cidr, 0))
    error_message = "Kubernetes API endpoint subnet CIDR must be a valid IPv4 CIDR."
  }
}

variable "worker_nodes_subnet_cidr" {
  description = "CIDR block for worker nodes subnet"
  type        = string
  default     = "10.0.1.0/24"
  validation {
    condition     = can(cidrhost(var.worker_nodes_subnet_cidr, 0))
    error_message = "Worker nodes subnet CIDR must be a valid IPv4 CIDR."
  }
}

variable "load_balancers_subnet_cidr" {
  description = "CIDR block for load balancers subnet"
  type        = string
  default     = "10.0.2.0/24"
  validation {
    condition     = can(cidrhost(var.load_balancers_subnet_cidr, 0))
    error_message = "Load balancers subnet CIDR must be a valid IPv4 CIDR."
  }
}

variable "pod_network_subnet_cidr" {
  description = "CIDR block for pod network subnet (VCN-Native CNI)"
  type        = string
  default     = "10.0.4.0/24"
  validation {
    condition     = can(cidrhost(var.pod_network_subnet_cidr, 0))
    error_message = "Pod network subnet CIDR must be a valid IPv4 CIDR."
  }
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for bastion subnet"
  type        = string
  default     = "10.0.3.0/24"
  validation {
    condition     = can(cidrhost(var.bastion_subnet_cidr, 0))
    error_message = "Bastion subnet CIDR must be a valid IPv4 CIDR."
  }
}

# Optional Features
variable "create_pod_network_subnet" {
  description = "Whether to create a dedicated subnet for pod network (VCN-Native CNI)"
  type        = bool
  default     = false
}

variable "create_bastion_subnet" {
  description = "Whether to create a bastion subnet"
  type        = bool
  default     = false
}

# Security Configuration
variable "load_balancer_ingress_ports" {
  description = "List of additional ports to allow ingress on load balancer subnet"
  type        = list(number)
  default     = [8080, 8443]
  validation {
    condition = alltrue([
      for port in var.load_balancer_ingress_ports : port >= 1 && port <= 65535
    ])
    error_message = "All ports must be between 1 and 65535."
  }
}

variable "bastion_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition = alltrue([
      for cidr in var.bastion_allowed_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All bastion allowed CIDRs must be valid IPv4 CIDRs."
  }
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

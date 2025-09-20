# Networking Module

This module creates the networking infrastructure required for Oracle Kubernetes Engine (OKE) clusters.

## Features

- **VCN with customizable CIDR blocks**
- **Multiple gateways**: Internet Gateway, NAT Gateway, Service Gateway
- **Subnets for different OKE components**:
  - Private subnet for Kubernetes API endpoint
  - Private subnet for worker nodes
  - Public subnet for load balancers
  - Optional pod network subnet (for VCN-Native CNI)
  - Optional bastion subnet
- **Security lists with least privilege access**
- **Proper routing tables for public and private subnets**

## Usage

```hcl
module "networking" {
  source = "./modules/networking"
  
  compartment_id       = var.compartment_id
  display_name_prefix  = "my-oke"
  dns_label           = "myoke"
  
  # VCN Configuration
  vcn_cidr_block = "10.0.0.0/16"
  
  # Subnet Configuration
  k8s_api_endpoint_subnet_cidr = "10.0.0.0/30"
  worker_nodes_subnet_cidr     = "10.0.1.0/24"
  load_balancers_subnet_cidr   = "10.0.2.0/24"
  
  # Optional features
  create_pod_network_subnet = true
  pod_network_subnet_cidr   = "10.0.4.0/24"
  
  create_bastion_subnet = true
  bastion_subnet_cidr   = "10.0.3.0/24"
  bastion_allowed_cidrs = ["203.0.113.0/24"]  # Your office IP range
  
  # Tagging
  freeform_tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

## Security

The module implements security best practices:

- **Least privilege access**: Security lists only allow necessary traffic
- **Network segmentation**: Different subnets for different components
- **Private subnets**: Worker nodes and API endpoint are not directly accessible from internet
- **Configurable bastion access**: Optional bastion host with configurable allowed CIDRs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| compartment_id | The OCID of the compartment | `string` | n/a | yes |
| display_name_prefix | Prefix for resource display names | `string` | n/a | yes |
| dns_label | DNS label for the VCN | `string` | n/a | yes |
| vcn_cidr_block | CIDR block for the VCN | `string` | `"10.0.0.0/16"` | no |
| k8s_api_endpoint_subnet_cidr | CIDR for K8s API endpoint subnet | `string` | `"10.0.0.0/30"` | no |
| worker_nodes_subnet_cidr | CIDR for worker nodes subnet | `string` | `"10.0.1.0/24"` | no |
| load_balancers_subnet_cidr | CIDR for load balancers subnet | `string` | `"10.0.2.0/24"` | no |
| create_pod_network_subnet | Create pod network subnet | `bool` | `false` | no |
| create_bastion_subnet | Create bastion subnet | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| vcn_id | The OCID of the VCN |
| subnet_ids | Map of subnet names to OCIDs |
| k8s_api_endpoint_subnet_id | OCID of K8s API endpoint subnet |
| worker_nodes_subnet_id | OCID of worker nodes subnet |
| load_balancers_subnet_id | OCID of load balancers subnet |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| oci | >= 5.0 |

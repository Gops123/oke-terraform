# OKE Cluster Module

This module creates an Oracle Kubernetes Engine (OKE) cluster with production-grade configurations.

## Features

- **Configurable cluster types**: BASIC_CLUSTER or ENHANCED_CLUSTER
- **Multiple CNI options**: FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE
- **Security features**: Image signing, KMS encryption, Pod Security Policy
- **Network integration**: Proper subnet and NSG configurations
- **Add-ons support**: Kubernetes dashboard, Tiller (deprecated)
- **Tagging support**: For cluster and sub-resources (PVs, LBs)

## Usage

```hcl
module "oke_cluster" {
  source = "./modules/oke-cluster"
  
  compartment_id       = var.compartment_id
  display_name_prefix  = "my-oke"
  
  # Network Configuration
  vcn_id                   = module.networking.vcn_id
  api_endpoint_subnet_id   = module.networking.k8s_api_endpoint_subnet_id
  load_balancer_subnet_ids = [module.networking.load_balancers_subnet_id]
  
  # Cluster Configuration
  kubernetes_version       = "v1.28.2"
  cluster_type            = "ENHANCED_CLUSTER"
  cni_type                = "OCI_VCN_IP_NATIVE"
  is_api_endpoint_public  = false
  
  # Network CIDRs
  pods_cidr     = "10.244.0.0/16"
  services_cidr = "10.96.0.0/16"
  
  # Security
  image_signing_enabled = true
  image_signing_key_ids = [var.kms_key_id]
  cluster_kms_key_id    = var.cluster_kms_key_id
  
  # Add-ons
  enable_kubernetes_dashboard = false
  enable_pod_security_policy  = true
  
  # Tagging
  freeform_tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
  
  # Sub-resource tagging
  pv_freeform_tags = {
    Component = "storage"
  }
  
  lb_freeform_tags = {
    Component = "networking"
  }
}
```

## Security Best Practices

This module implements several security best practices:

1. **Private API endpoint by default**: API endpoint is private unless explicitly made public
2. **Image signing support**: Optional verification of container images
3. **KMS encryption**: Optional encryption of cluster secrets with customer-managed keys
4. **Pod Security Policy**: Optional admission controller for pod security
5. **Network Security Groups**: Support for additional NSG-based security

## CNI Types

### FLANNEL_OVERLAY
- Traditional overlay networking
- Simpler to setup and manage
- Pods get IPs from pods_cidr range

### OCI_VCN_IP_NATIVE
- Pods get IPs directly from VCN subnets
- Better performance and integration with OCI networking
- Requires proper subnet planning
- Recommended for production workloads

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| compartment_id | The OCID of the compartment | `string` | n/a | yes |
| display_name_prefix | Prefix for resource names | `string` | n/a | yes |
| vcn_id | The OCID of the VCN | `string` | n/a | yes |
| api_endpoint_subnet_id | Subnet for API endpoint | `string` | n/a | yes |
| load_balancer_subnet_ids | Subnets for load balancers | `list(string)` | n/a | yes |
| kubernetes_version | Kubernetes version | `string` | n/a | yes |
| cluster_type | Cluster type | `string` | `"ENHANCED_CLUSTER"` | no |
| cni_type | CNI type | `string` | `"OCI_VCN_IP_NATIVE"` | no |
| is_api_endpoint_public | Public API endpoint | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The OCID of the cluster |
| cluster_name | The name of the cluster |
| cluster_endpoints | The endpoints of the cluster |
| cluster_ca_certificate | CA certificate for kubeconfig |
| cluster_endpoint_url | Endpoint URL for kubeconfig |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| oci | >= 5.0 |

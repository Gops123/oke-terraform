# OKE Terraform Infrastructure

Production-ready Terraform configuration for Oracle Kubernetes Engine (OKE) clusters on OCI.

## Features

- **Modular architecture** with reusable components
- **Environment-specific configurations** (dev, staging, prod)
- **Security best practices** and compliance features
- **Multiple node pools** with different configurations
- **VCN-Native CNI** support
- **Comprehensive Makefile** for easy management

## Prerequisites

1. **OCI Account** with appropriate permissions
2. **OCI CLI** installed and configured
3. **Terraform** >= 1.0
4. **kubectl** (for cluster management)
5. **SSH key pair** (for node access)

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd oke_terraform_for_beginners

# Copy environment configuration
cp environments/dev/terraform.tfvars ./terraform.tfvars

# Set up OCI credentials
export TF_VAR_tenancy_ocid="ocid1.tenancy.oc1..aaaaaaaa..."
export TF_VAR_user_ocid="ocid1.user.oc1..aaaaaaaa..."
export TF_VAR_fingerprint="12:34:56:78:90:ab:cd:ef:12:34:56:78:90:ab:cd:ef"
export TF_VAR_private_key_path="~/.oci/oci_api_key.pem"
export TF_VAR_region="us-ashburn-1"
export TF_VAR_compartment_id="ocid1.compartment.oc1..aaaaaaaa..."
```

### 2. Deploy Infrastructure

```bash
# Show available commands
make help

# Deploy development environment
make dev

# Deploy staging environment
make staging

# Deploy production environment (with confirmation)
make prod
```

### 3. Configure kubectl

```bash
# Generate kubeconfig
make kubeconfig

# Test connection
make kubectl-test
```

## Project Structure

```
├── modules/                    # Reusable Terraform modules
│   ├── networking/            # VCN, subnets, security
│   ├── oke-cluster/          # OKE cluster configuration
│   └── node-pool/            # Worker node pools
├── environments/             # Environment-specific configs
│   ├── dev/                 # Development environment
│   ├── staging/             # Staging environment
│   └── prod/                # Production environment
├── examples/                # Usage examples
├── main.tf                 # Root configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Version constraints
├── Makefile               # Management commands
└── README.md             # This file
```

## Configuration

### Environment Selection

```bash
# Development
make env-dev

# Staging  
make env-staging

# Production
make env-prod
```

### Basic Configuration

Update `terraform.tfvars`:

```hcl
# Project Configuration
project_name = "my-oke-project"
environment  = "dev"

# Network Configuration  
vcn_dns_label = "myoke"
vcn_cidr_block = "10.0.0.0/16"

# OKE Configuration
kubernetes_version = "v1.28.2"
cluster_type = "ENHANCED_CLUSTER"
cni_type = "OCI_VCN_IP_NATIVE"

# Node Pools
node_pools = {
  general = {
    shape = "VM.Standard.E4.Flex"
    image_id = "ocid1.image.oc1.iad.aaaaaaaa..."
    size = 3
    availability_domains = ["AD-1", "AD-2", "AD-3"]
    
    shape_config = {
      memory_in_gbs = 32
      ocpus = 4
    }
  }
}
```

## Management Commands

### Cluster Operations

```bash
# Build complete cluster
make build-cluster

# Update cluster configuration
make update-cluster

# Update worker node pools
make update-worker-tier

# Scale node pool
make scale-nodepool POOL_NAME=general SIZE=5

# Upgrade Kubernetes
make upgrade-kubernetes VERSION=v1.29.0

# Check node pool status
make nodepool-status
```

### Basic Operations

```bash
# Initialize Terraform
make init

# Create plan
make plan

# Apply configuration
make apply

# Destroy infrastructure
make destroy

# Show status
make status
```

## Environment Configurations

### Development
- **Cost-optimized** with BASIC_CLUSTER
- **Public API endpoint** for easy access
- **Smaller node pools** for development

### Staging
- **Production-like** ENHANCED_CLUSTER
- **Private API endpoint** for testing
- **Security features** enabled

### Production
- **High availability** across multiple ADs
- **Maximum security** features enabled
- **Multiple node pools** for different workloads

## Security Features

- **Private subnets** for worker nodes and API endpoint
- **Security lists** with minimal required access
- **Image signing** verification
- **KMS encryption** for secrets and volumes
- **Pod Security Policy** support

## Cost Optimization

- **Right-sized instances** for different workloads
- **ARM-based nodes** for cost savings
- **Resource tagging** for cost allocation
- **Auto-scaling** ready architecture

## Examples

- **[Basic Example](examples/basic/)** - Minimal OKE cluster
- **[Multi-tier Application](examples/multi-tier/)** - Complex workload deployment
- **[Security Hardening](examples/security/)** - Maximum security configuration

## Support

- **OCI OKE Documentation**: https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm
- **Terraform OCI Provider**: https://registry.terraform.io/providers/oracle/oci/latest/docs
- **Kubernetes Documentation**: https://kubernetes.io/docs/

## License

This project is licensed under the Apache License 2.0.
# Basic OKE Example

This example demonstrates how to create a minimal Oracle Kubernetes Engine (OKE) cluster using the modular Terraform configuration.

## What this example creates

- **VCN** with basic networking (public and private subnets)
- **OKE Cluster** (BASIC_CLUSTER type for cost efficiency)
- **Single Node Pool** with 2 nodes
- **Load Balancer subnet** for service exposure
- **Pod Network subnet** for VCN-Native CNI

## Prerequisites

1. **OCI Account** with appropriate permissions
2. **OCI CLI** configured
3. **Terraform** >= 1.0 installed
4. **SSH Key Pair** (optional, for node access)

## Quick Start

1. **Set up OCI credentials**:
   ```bash
   export TF_VAR_tenancy_ocid="ocid1.tenancy.oc1..aaaaaaaa..."
   export TF_VAR_user_ocid="ocid1.user.oc1..aaaaaaaa..."
   export TF_VAR_fingerprint="12:34:56:78:90:ab:cd:ef:12:34:56:78:90:ab:cd:ef"
   export TF_VAR_private_key_path="~/.oci/oci_api_key.pem"
   export TF_VAR_region="us-ashburn-1"
   export TF_VAR_compartment_id="ocid1.compartment.oc1..aaaaaaaa..."
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan the deployment**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

5. **Generate kubeconfig**:
   ```bash
   oci ce cluster create-kubeconfig \
     --cluster-id $(terraform output -raw cluster_id) \
     --file $HOME/.kube/config \
     --region $(terraform output -raw region) \
     --token-version 2.0.0
   ```

6. **Verify the cluster**:
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

## Configuration Details

### Cluster Configuration
- **Type**: BASIC_CLUSTER (cost-effective)
- **CNI**: VCN-Native (OCI_VCN_IP_NATIVE)
- **API Endpoint**: Public (for easy access)
- **Dashboard**: Enabled (for development)

### Node Pool Configuration
- **Shape**: VM.Standard.E4.Flex (2 OCPU, 16GB RAM)
- **Size**: 2 nodes
- **Image**: Latest OKE-optimized Oracle Linux image
- **Boot Volume**: 50GB
- **Placement**: Across 2 availability domains

### Network Configuration
- **VCN CIDR**: 10.0.0.0/16
- **API Endpoint Subnet**: 10.0.0.0/30 (private)
- **Worker Nodes Subnet**: 10.0.1.0/24 (private)
- **Load Balancers Subnet**: 10.0.2.0/24 (public)
- **Pod Network Subnet**: 10.0.4.0/24 (private)

## Customization

### Change Node Pool Size
```hcl
node_pools = {
  default = {
    # ... other configuration
    size = 3  # Change from 2 to 3 nodes
  }
}
```

### Use Different Instance Shape
```hcl
node_pools = {
  default = {
    shape = "VM.Standard.E3.Flex"  # Different shape
    shape_config = {
      memory_in_gbs = 32
      ocpus        = 4
    }
    # ... other configuration
  }
}
```

### Add SSH Access to Nodes
```hcl
node_pools = {
  default = {
    # ... other configuration
    ssh_public_key = file("~/.ssh/id_rsa.pub")
  }
}
```

## Cost Considerations

This basic configuration is designed to be cost-effective:

- **BASIC_CLUSTER**: No additional charges for control plane
- **VM.Standard.E4.Flex**: Cost-effective flexible shapes
- **2 nodes**: Minimal for HA while keeping costs low
- **50GB boot volumes**: Sufficient for basic workloads

Estimated monthly cost: ~$100-150 USD (varies by region and usage)

## Security Considerations

This example prioritizes ease of use over security:

- **Public API endpoint**: Easy access but less secure
- **No image signing**: Simplified setup
- **Basic security lists**: Standard OKE security

For production use, consider:
- Private API endpoint
- Enabling image signing
- Restricting security list rules
- Using customer-managed encryption keys

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Next Steps

1. **Deploy sample applications**
2. **Set up monitoring and logging**
3. **Configure ingress controllers**
4. **Implement GitOps workflows**
5. **Review security hardening**

## Troubleshooting

### Common Issues

1. **Insufficient Permissions**
   - Ensure your user has required IAM policies
   - Check compartment permissions

2. **Resource Limits**
   - Verify service limits in your tenancy
   - Check availability domain capacity

3. **Network Connectivity**
   - Verify security list rules
   - Check route table configurations

### Getting Help

- **OCI Documentation**: https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm
- **Terraform OCI Provider**: https://registry.terraform.io/providers/oracle/oci/latest/docs
- **OKE Troubleshooting**: https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm

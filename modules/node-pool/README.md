# Node Pool Module

This module creates OKE node pools with flexible configuration options for production workloads.

## Features

- **Multiple node pools**: Support for creating multiple node pools with different configurations
- **Flexible shapes**: Support for VM Standard, Optimized, and ARM-based shapes
- **Auto-scaling ready**: Configurable node pool sizes
- **Node cycling**: Rolling updates for node maintenance
- **Security features**: Boot volume encryption, PV encryption in transit
- **VCN-Native CNI support**: Pod subnet configuration
- **Advanced placement**: Availability domain and fault domain control
- **Custom node configuration**: SSH keys, cloud-init scripts

## Usage

### Basic Configuration

```hcl
module "node_pools" {
  source = "./modules/node-pool"
  
  compartment_id       = var.compartment_id
  display_name_prefix  = "my-oke"
  cluster_id          = module.oke_cluster.cluster_id
  kubernetes_version  = "v1.28.2"
  worker_subnet_id    = module.networking.worker_nodes_subnet_id
  cni_type           = "OCI_VCN_IP_NATIVE"
  
  node_pools = {
    general = {
      shape                = "VM.Standard.E4.Flex"
      image_id            = "ocid1.image.oc1.iad.aaaaaaaa..."
      size                = 3
      availability_domains = ["AD-1", "AD-2", "AD-3"]
      
      shape_config = {
        memory_in_gbs = 16
        ocpus        = 2
      }
      
      node_labels = {
        node-type = "general"
        environment = "production"
      }
    }
  }
}
```

### Advanced Multi-Pool Configuration

```hcl
module "node_pools" {
  source = "./modules/node-pool"
  
  compartment_id       = var.compartment_id
  display_name_prefix  = "my-oke"
  cluster_id          = module.oke_cluster.cluster_id
  kubernetes_version  = "v1.28.2"
  worker_subnet_id    = module.networking.worker_nodes_subnet_id
  pod_subnet_ids      = [module.networking.pod_network_subnet_id]
  cni_type           = "OCI_VCN_IP_NATIVE"
  
  node_pools = {
    # General purpose pool
    general = {
      shape                = "VM.Standard.E4.Flex"
      image_id            = var.worker_node_image_id
      size                = 3
      availability_domains = data.oci_identity_availability_domains.ads.availability_domains[*].name
      boot_volume_size_gb = 100
      
      shape_config = {
        memory_in_gbs = 32
        ocpus        = 4
      }
      
      node_labels = {
        node-type = "general"
        pool      = "default"
      }
      
      node_cycling = {
        enabled             = true
        maximum_surge      = "1"
        maximum_unavailable = "0"
      }
      
      pv_encryption_in_transit = true
      ssh_public_key          = file("~/.ssh/id_rsa.pub")
    }
    
    # High-memory pool for specific workloads
    memory_optimized = {
      shape                = "VM.Standard.E4.Flex"
      image_id            = var.worker_node_image_id
      size                = 2
      availability_domains = [data.oci_identity_availability_domains.ads.availability_domains[0].name]
      boot_volume_size_gb = 200
      
      shape_config = {
        memory_in_gbs = 128
        ocpus        = 8
      }
      
      node_labels = {
        node-type = "memory-optimized"
        workload  = "high-memory"
      }
      
      max_pods_per_node = 31
      
      node_cycling = {
        enabled             = true
        maximum_surge      = "1"
        maximum_unavailable = "0"
      }
    }
    
    # ARM-based pool for cost optimization
    arm_pool = {
      shape                = "VM.Standard.A1.Flex"
      image_id            = var.arm_worker_node_image_id
      size                = 2
      availability_domains = data.oci_identity_availability_domains.ads.availability_domains[*].name
      boot_volume_size_gb = 50
      
      shape_config = {
        memory_in_gbs = 24
        ocpus        = 4
      }
      
      node_labels = {
        node-type = "arm"
        arch      = "arm64"
      }
    }
  }
  
  freeform_tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

## Node Pool Configuration Options

### Shape Configuration
- **VM.Standard.E4.Flex**: General purpose with flexible CPU/memory
- **VM.Standard.A1.Flex**: ARM-based for cost optimization
- **VM.Optimized3.Flex**: CPU-optimized workloads
- **BM.Standard.E4.128**: Bare metal for high performance

### Security Features
- **Boot volume encryption**: Encrypt boot volumes with KMS keys
- **PV encryption in transit**: Encrypt persistent volume traffic
- **SSH access**: Configure SSH keys for node access
- **Network security**: Integration with NSGs and security lists

### Node Management
- **Node cycling**: Rolling updates for maintenance windows
- **Node eviction**: Graceful pod eviction during updates
- **Custom metadata**: Cloud-init scripts and user data

## Best Practices

1. **Use multiple availability domains** for high availability
2. **Enable node cycling** for automated maintenance
3. **Use appropriate shapes** for workload requirements
4. **Configure resource limits** to prevent noisy neighbors
5. **Use labels and taints** for workload scheduling
6. **Monitor node utilization** and adjust pool sizes accordingly

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| compartment_id | Compartment OCID | `string` | n/a | yes |
| cluster_id | OKE cluster OCID | `string` | n/a | yes |
| worker_subnet_id | Worker subnet OCID | `string` | n/a | yes |
| kubernetes_version | Kubernetes version | `string` | n/a | yes |
| node_pools | Node pool configurations | `map(object)` | n/a | yes |
| cni_type | CNI type | `string` | `"OCI_VCN_IP_NATIVE"` | no |
| pod_subnet_ids | Pod subnet OCIDs | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| node_pool_ids | Map of pool names to OCIDs |
| node_pool_details | Detailed pool information |
| node_pool_summary | Summary statistics |
| node_pool_nodes | Node information (sensitive) |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| oci | >= 5.0 |

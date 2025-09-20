##############################################################################
# Node Pool Module Outputs
##############################################################################

output "node_pool_ids" {
  description = "Map of node pool names to their OCIDs"
  value = {
    for pool_name, pool in oci_containerengine_node_pool.this : pool_name => pool.id
  }
}

output "node_pool_details" {
  description = "Detailed information about all node pools"
  value = {
    for pool_name, pool in oci_containerengine_node_pool.this : pool_name => {
      id                = pool.id
      name              = pool.name
      state             = pool.state
      kubernetes_version = pool.kubernetes_version
      node_shape        = pool.node_shape
      size              = pool.node_config_details[0].size
      subnet_id         = tolist(pool.node_config_details[0].placement_configs)[0].subnet_id
    }
  }
}

output "node_pool_nodes" {
  description = "Information about nodes in each pool"
  value = {
    for pool_name, pool in oci_containerengine_node_pool.this : pool_name => pool.nodes
  }
  sensitive = true
}

output "node_pool_states" {
  description = "Map of node pool names to their current states"
  value = {
    for pool_name, pool in oci_containerengine_node_pool.this : pool_name => pool.state
  }
}

output "node_pool_kubernetes_versions" {
  description = "Map of node pool names to their Kubernetes versions"
  value = {
    for pool_name, pool in oci_containerengine_node_pool.this : pool_name => pool.kubernetes_version
  }
}

output "node_pool_shapes" {
  description = "Map of node pool names to their node shapes"
  value = {
    for pool_name, pool in oci_containerengine_node_pool.this : pool_name => pool.node_shape
  }
}

output "node_pool_sizes" {
  description = "Map of node pool names to their current sizes"
  value = {
    for pool_name, pool in oci_containerengine_node_pool.this : pool_name => pool.node_config_details[0].size
  }
}

# Outputs for monitoring and management
output "node_pool_summary" {
  description = "Summary information for all node pools"
  value = {
    total_pools = length(oci_containerengine_node_pool.this)
    total_nodes = sum([
      for pool in oci_containerengine_node_pool.this : pool.node_config_details[0].size
    ])
    pool_names = keys(oci_containerengine_node_pool.this)
    shapes_used = distinct([
      for pool in oci_containerengine_node_pool.this : pool.node_shape
    ])
  }
}

# Individual node pool outputs (useful for single pool deployments)
output "first_node_pool_id" {
  description = "The OCID of the first node pool (for backward compatibility)"
  value       = length(oci_containerengine_node_pool.this) > 0 ? values(oci_containerengine_node_pool.this)[0].id : null
}

output "first_node_pool_name" {
  description = "The name of the first node pool (for backward compatibility)"
  value       = length(oci_containerengine_node_pool.this) > 0 ? values(oci_containerengine_node_pool.this)[0].name : null
}

# Outputs for integration with other systems
output "node_pool_metadata" {
  description = "Metadata about node pools for use by other modules"
  value = {
    for pool_name, pool in oci_containerengine_node_pool.this : pool_name => {
      id                = pool.id
      name              = pool.name
      compartment_id    = pool.compartment_id
      cluster_id        = pool.cluster_id
      kubernetes_version = pool.kubernetes_version
      node_shape        = pool.node_shape
      size              = pool.node_config_details[0].size
      availability_domains = [
        for placement in pool.node_config_details[0].placement_configs : placement.availability_domain
      ]
      subnet_id = tolist(pool.node_config_details[0].placement_configs)[0].subnet_id
      state     = pool.state
    }
  }
}

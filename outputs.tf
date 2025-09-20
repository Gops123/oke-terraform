# OKE Infrastructure Outputs

# Project Information
output "project_info" {
  description = "Project information"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.region
    created_by   = "Terraform"
  }
}

# Networking Outputs
output "networking" {
  description = "Networking infrastructure details"
  value = {
    vcn_id                        = module.networking.vcn_id
    vcn_cidr_block               = module.networking.vcn_cidr_block
    internet_gateway_id          = module.networking.internet_gateway_id
    nat_gateway_id               = module.networking.nat_gateway_id
    service_gateway_id           = module.networking.service_gateway_id
    
    # Subnets
    k8s_api_endpoint_subnet_id   = module.networking.k8s_api_endpoint_subnet_id
    worker_nodes_subnet_id       = module.networking.worker_nodes_subnet_id
    load_balancers_subnet_id     = module.networking.load_balancers_subnet_id
    pod_network_subnet_id        = module.networking.pod_network_subnet_id
    bastion_subnet_id            = module.networking.bastion_subnet_id
    
    # Route Tables
    public_route_table_id        = module.networking.public_route_table_id
    private_route_table_id       = module.networking.private_route_table_id
    
    # Security Lists
    k8s_api_endpoint_security_list_id = module.networking.k8s_api_endpoint_security_list_id
    worker_nodes_security_list_id     = module.networking.worker_nodes_security_list_id
    load_balancers_security_list_id   = module.networking.load_balancers_security_list_id
    bastion_security_list_id          = module.networking.bastion_security_list_id
  }
}

# Easy access subnet IDs for reference
output "subnet_ids" {
  description = "Map of subnet names to their OCIDs"
  value       = module.networking.subnet_ids
}

# OKE Cluster Outputs
output "cluster" {
  description = "OKE cluster details"
  value = {
    id                     = module.oke_cluster.cluster_id
    name                   = module.oke_cluster.cluster_name
    state                  = module.oke_cluster.cluster_state
    kubernetes_version     = module.oke_cluster.cluster_kubernetes_version
    type                   = module.oke_cluster.cluster_type
    vcn_id                = module.oke_cluster.cluster_vcn_id
    available_upgrades     = module.oke_cluster.cluster_available_kubernetes_upgrades
  }
}

output "cluster_endpoints" {
  description = "Cluster endpoint information"
  value       = module.oke_cluster.cluster_endpoints
  sensitive   = true
}

# Convenient outputs for kubeconfig generation
output "kubeconfig_data" {
  description = "Data needed to generate kubeconfig"
  value = {
    cluster_id            = module.oke_cluster.cluster_id
    cluster_name          = module.oke_cluster.cluster_name
    cluster_endpoint      = module.oke_cluster.cluster_endpoint_url
    cluster_ca_certificate = module.oke_cluster.cluster_ca_certificate
    region               = var.region
  }
  sensitive = true
}

# Node Pools Outputs
output "node_pools" {
  description = "Node pool details"
  value = {
    ids               = module.node_pools.node_pool_ids
    details          = module.node_pools.node_pool_details
    states           = module.node_pools.node_pool_states
    kubernetes_versions = module.node_pools.node_pool_kubernetes_versions
    shapes           = module.node_pools.node_pool_shapes
    sizes            = module.node_pools.node_pool_sizes
    summary          = module.node_pools.node_pool_summary
  }
}

output "node_pool_nodes" {
  description = "Information about nodes in each pool"
  value       = module.node_pools.node_pool_nodes
  sensitive   = true
}

# Infrastructure Summary
output "infrastructure_summary" {
  description = "Summary of the created infrastructure"
  value = {
    # Basic Info
    project_name      = var.project_name
    environment       = var.environment
    region           = var.region
    compartment_id   = var.compartment_id
    
    # Network Summary
    vcn_id           = module.networking.vcn_id
    vcn_cidr         = module.networking.vcn_cidr_block
    subnets_created  = length(module.networking.subnet_ids)
    
    # Cluster Summary
    cluster_id       = module.oke_cluster.cluster_id
    cluster_name     = module.oke_cluster.cluster_name
    cluster_type     = module.oke_cluster.cluster_type
    kubernetes_version = module.oke_cluster.cluster_kubernetes_version
    cni_type         = var.cni_type
    
    # Node Pool Summary
    total_node_pools = module.node_pools.node_pool_summary.total_pools
    total_nodes      = module.node_pools.node_pool_summary.total_nodes
    node_pool_names  = module.node_pools.node_pool_summary.pool_names
    node_shapes_used = module.node_pools.node_pool_summary.shapes_used
    
    # Security Features
    api_endpoint_public = var.is_api_endpoint_public
    image_signing_enabled = var.image_signing_enabled
    pod_security_policy_enabled = var.enable_pod_security_policy
    
    # Network Features
    cni_type                 = var.cni_type
    pod_network_subnet_created = var.create_pod_network_subnet
    bastion_subnet_created   = var.create_bastion_subnet
  }
}

# Useful Commands
output "useful_commands" {
  description = "Useful commands for managing the cluster"
  value = {
    # OCI CLI commands
    generate_kubeconfig = "oci ce cluster create-kubeconfig --cluster-id ${module.oke_cluster.cluster_id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT"
    get_cluster_info    = "oci ce cluster get --cluster-id ${module.oke_cluster.cluster_id}"
    list_node_pools     = "oci ce node-pool list --cluster-id ${module.oke_cluster.cluster_id} --compartment-id ${var.compartment_id}"
    
    # kubectl commands (after kubeconfig setup)
    get_nodes          = "kubectl get nodes"
    get_pods_all       = "kubectl get pods --all-namespaces"
    cluster_info       = "kubectl cluster-info"
    
    # Terraform commands
    terraform_plan     = "terraform plan"
    terraform_apply    = "terraform apply"
    terraform_destroy  = "terraform destroy"
    terraform_refresh  = "terraform refresh"
  }
}

# Connection Information
output "connection_info" {
  description = "Information for connecting to the cluster"
  value = {
    cluster_id   = module.oke_cluster.cluster_id
    region       = var.region
    compartment_id = var.compartment_id
    
    # API endpoints (sensitive)
    public_endpoint_available  = var.is_api_endpoint_public
    
    # Instructions
    setup_instructions = [
      "1. Install OCI CLI: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm",
      "2. Configure OCI CLI: oci setup config",
      "3. Generate kubeconfig: oci ce cluster create-kubeconfig --cluster-id ${module.oke_cluster.cluster_id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0",
      "4. Verify connection: kubectl get nodes",
      "5. Install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/",
      var.is_api_endpoint_public ? "Note: Cluster API endpoint is PUBLIC" : "Note: Cluster API endpoint is PRIVATE - use bastion or VPN for access"
    ]
  }
}
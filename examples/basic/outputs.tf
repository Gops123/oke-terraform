##############################################################################
# Basic Example Outputs
##############################################################################

output "cluster_id" {
  description = "The OCID of the OKE cluster"
  value       = module.oke_cluster.cluster_id
}

output "cluster_name" {
  description = "The name of the OKE cluster"
  value       = module.oke_cluster.cluster_name
}

output "kubeconfig_command" {
  description = "Command to generate kubeconfig"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${module.oke_cluster.cluster_id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0"
}

output "vcn_id" {
  description = "The OCID of the VCN"
  value       = module.networking.vcn_id
}

output "node_pool_ids" {
  description = "The OCIDs of the node pools"
  value       = module.node_pools.node_pool_ids
}

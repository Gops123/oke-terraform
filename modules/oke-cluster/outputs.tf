##############################################################################
# OKE Cluster Module Outputs
##############################################################################

output "cluster_id" {
  description = "The OCID of the OKE cluster"
  value       = oci_containerengine_cluster.this.id
}

output "cluster_name" {
  description = "The name of the OKE cluster"
  value       = oci_containerengine_cluster.this.name
}

output "cluster_state" {
  description = "The state of the OKE cluster"
  value       = oci_containerengine_cluster.this.state
}

output "cluster_kubernetes_version" {
  description = "The Kubernetes version of the cluster"
  value       = oci_containerengine_cluster.this.kubernetes_version
}

output "cluster_type" {
  description = "The type of the cluster (BASIC_CLUSTER or ENHANCED_CLUSTER)"
  value       = oci_containerengine_cluster.this.type
}

output "cluster_endpoints" {
  description = "The endpoints of the cluster"
  value       = oci_containerengine_cluster.this.endpoints
  sensitive   = true
}

output "cluster_endpoint_config" {
  description = "The endpoint configuration of the cluster"
  value       = oci_containerengine_cluster.this.endpoint_config
}

output "cluster_vcn_id" {
  description = "The VCN ID where the cluster is deployed"
  value       = oci_containerengine_cluster.this.vcn_id
}

output "cluster_available_kubernetes_upgrades" {
  description = "Available Kubernetes upgrades for the cluster"
  value       = oci_containerengine_cluster.this.available_kubernetes_upgrades
}

output "cluster_options" {
  description = "The options configured for the cluster"
  value       = oci_containerengine_cluster.this.options
  sensitive   = true
}

output "cluster_metadata" {
  description = "Metadata about the cluster for use by other modules"
  value = {
    id                 = oci_containerengine_cluster.this.id
    name               = oci_containerengine_cluster.this.name
    kubernetes_version = oci_containerengine_cluster.this.kubernetes_version
    vcn_id            = oci_containerengine_cluster.this.vcn_id
    compartment_id    = oci_containerengine_cluster.this.compartment_id
    type              = oci_containerengine_cluster.this.type
    state             = oci_containerengine_cluster.this.state
  }
}

# Convenient outputs for kubeconfig generation
output "cluster_ca_certificate" {
  description = "The cluster CA certificate for kubeconfig"
  value       = oci_containerengine_cluster.this.endpoints
  sensitive   = true
}

output "cluster_endpoint_url" {
  description = "The cluster endpoint URL for kubeconfig"
  value       = oci_containerengine_cluster.this.endpoints
  sensitive   = true
}

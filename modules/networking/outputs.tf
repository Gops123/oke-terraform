##############################################################################
# Networking Module Outputs
##############################################################################

# VCN Outputs
output "vcn_id" {
  description = "The OCID of the VCN"
  value       = oci_core_vcn.this.id
}

output "vcn_cidr_block" {
  description = "The CIDR block of the VCN"
  value       = oci_core_vcn.this.cidr_block
}

output "vcn_default_dhcp_options_id" {
  description = "The OCID of the default DHCP options"
  value       = oci_core_vcn.this.default_dhcp_options_id
}

output "vcn_default_security_list_id" {
  description = "The OCID of the default security list"
  value       = oci_core_vcn.this.default_security_list_id
}

# Gateway Outputs
output "internet_gateway_id" {
  description = "The OCID of the Internet Gateway"
  value       = oci_core_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "The OCID of the NAT Gateway"
  value       = oci_core_nat_gateway.this.id
}

output "service_gateway_id" {
  description = "The OCID of the Service Gateway"
  value       = oci_core_service_gateway.this.id
}

# Route Table Outputs
output "public_route_table_id" {
  description = "The OCID of the public route table"
  value       = oci_core_default_route_table.public.id
}

output "private_route_table_id" {
  description = "The OCID of the private route table"
  value       = oci_core_route_table.private.id
}

# Subnet Outputs
output "k8s_api_endpoint_subnet_id" {
  description = "The OCID of the Kubernetes API endpoint subnet"
  value       = oci_core_subnet.k8s_api_endpoint.id
}

output "k8s_api_endpoint_subnet_cidr" {
  description = "The CIDR block of the Kubernetes API endpoint subnet"
  value       = oci_core_subnet.k8s_api_endpoint.cidr_block
}

output "worker_nodes_subnet_id" {
  description = "The OCID of the worker nodes subnet"
  value       = oci_core_subnet.worker_nodes.id
}

output "worker_nodes_subnet_cidr" {
  description = "The CIDR block of the worker nodes subnet"
  value       = oci_core_subnet.worker_nodes.cidr_block
}

output "load_balancers_subnet_id" {
  description = "The OCID of the load balancers subnet"
  value       = oci_core_subnet.load_balancers.id
}

output "load_balancers_subnet_cidr" {
  description = "The CIDR block of the load balancers subnet"
  value       = oci_core_subnet.load_balancers.cidr_block
}

output "pod_network_subnet_id" {
  description = "The OCID of the pod network subnet (if created)"
  value       = var.create_pod_network_subnet ? oci_core_subnet.pod_network[0].id : null
}

output "pod_network_subnet_cidr" {
  description = "The CIDR block of the pod network subnet (if created)"
  value       = var.create_pod_network_subnet ? oci_core_subnet.pod_network[0].cidr_block : null
}

output "bastion_subnet_id" {
  description = "The OCID of the bastion subnet (if created)"
  value       = var.create_bastion_subnet ? oci_core_subnet.bastion[0].id : null
}

output "bastion_subnet_cidr" {
  description = "The CIDR block of the bastion subnet (if created)"
  value       = var.create_bastion_subnet ? oci_core_subnet.bastion[0].cidr_block : null
}

# Security List Outputs
output "k8s_api_endpoint_security_list_id" {
  description = "The OCID of the Kubernetes API endpoint security list"
  value       = oci_core_security_list.k8s_api_endpoint.id
}

output "worker_nodes_security_list_id" {
  description = "The OCID of the worker nodes security list"
  value       = oci_core_security_list.worker_nodes.id
}

output "load_balancers_security_list_id" {
  description = "The OCID of the load balancers security list"
  value       = oci_core_security_list.load_balancers.id
}

output "bastion_security_list_id" {
  description = "The OCID of the bastion security list (if created)"
  value       = var.create_bastion_subnet ? oci_core_security_list.bastion[0].id : null
}

# Subnet IDs for OKE cluster configuration
output "subnet_ids" {
  description = "Map of subnet names to their OCIDs for easy reference"
  value = {
    k8s_api_endpoint = oci_core_subnet.k8s_api_endpoint.id
    worker_nodes     = oci_core_subnet.worker_nodes.id
    load_balancers   = oci_core_subnet.load_balancers.id
    pod_network      = var.create_pod_network_subnet ? oci_core_subnet.pod_network[0].id : null
    bastion          = var.create_bastion_subnet ? oci_core_subnet.bastion[0].id : null
  }
}

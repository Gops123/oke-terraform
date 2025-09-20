##############################################################################
# Subnet Resources for OKE
##############################################################################

# Private Subnet for Kubernetes API Endpoint
resource "oci_core_subnet" "k8s_api_endpoint" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.k8s_api_endpoint_subnet_cidr
  display_name               = "${var.display_name_prefix}-K8S-API-Endpoint-Subnet"
  dns_label                  = "${var.dns_label}k8api"
  dhcp_options_id            = oci_core_vcn.this.default_dhcp_options_id
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.k8s_api_endpoint.id]
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Private Subnet for Worker Nodes
resource "oci_core_subnet" "worker_nodes" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.worker_nodes_subnet_cidr
  display_name               = "${var.display_name_prefix}-Worker-Nodes-Subnet"
  dns_label                  = "${var.dns_label}workers"
  dhcp_options_id            = oci_core_vcn.this.default_dhcp_options_id
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.worker_nodes.id]
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Public Subnet for Load Balancers
resource "oci_core_subnet" "load_balancers" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.load_balancers_subnet_cidr
  display_name               = "${var.display_name_prefix}-Load-Balancers-Subnet"
  dns_label                  = "${var.dns_label}loadbal"
  dhcp_options_id            = oci_core_vcn.this.default_dhcp_options_id
  route_table_id             = oci_core_default_route_table.public.id
  security_list_ids          = [oci_core_security_list.load_balancers.id]
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Optional: Pod Network Subnet (for VCN-Native CNI)
resource "oci_core_subnet" "pod_network" {
  count = var.create_pod_network_subnet ? 1 : 0
  
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.pod_network_subnet_cidr
  display_name               = "${var.display_name_prefix}-Pod-Network-Subnet"
  dns_label                  = "${var.dns_label}pods"
  dhcp_options_id            = oci_core_vcn.this.default_dhcp_options_id
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.worker_nodes.id]
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Optional: Bastion Subnet
resource "oci_core_subnet" "bastion" {
  count = var.create_bastion_subnet ? 1 : 0
  
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.bastion_subnet_cidr
  display_name               = "${var.display_name_prefix}-Bastion-Subnet"
  dns_label                  = "${var.dns_label}bastion"
  dhcp_options_id            = oci_core_vcn.this.default_dhcp_options_id
  route_table_id             = oci_core_default_route_table.public.id
  security_list_ids          = [oci_core_security_list.bastion[0].id]
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

##############################################################################
# Networking Module - Production Grade
# 
# This module creates:
# - VCN with customizable CIDR
# - Internet Gateway, NAT Gateway, Service Gateway
# - Subnets for different OKE components with proper routing and security
# - Security lists with least privilege access
##############################################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
}

# Get all OCI services for service gateway
data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# Core VCN
resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr_block
  display_name   = "${var.display_name_prefix}-VCN"
  dns_label      = var.dns_label
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Internet Gateway
resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.display_name_prefix}-Internet-Gateway"
  enabled        = true
  vcn_id         = oci_core_vcn.this.id
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# NAT Gateway
resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.display_name_prefix}-NAT-Gateway"
  vcn_id         = oci_core_vcn.this.id
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Service Gateway
resource "oci_core_service_gateway" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.display_name_prefix}-Service-Gateway"
  vcn_id         = oci_core_vcn.this.id

  services {
    service_id = lookup(data.oci_core_services.all_oci_services.services[0], "id")
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Default Route Table (for public subnets)
resource "oci_core_default_route_table" "public" {
  compartment_id             = var.compartment_id
  display_name               = "${var.display_name_prefix}-Public-Route-Table"
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id

  route_rules {
    description       = "Default route to Internet Gateway"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Route Table for private subnets
resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  display_name   = "${var.display_name_prefix}-Private-Route-Table"
  vcn_id         = oci_core_vcn.this.id

  route_rules {
    description       = "Route to NAT Gateway for internet access"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }

  route_rules {
    description       = "Route to Service Gateway for OCI services"
    destination       = lookup(data.oci_core_services.all_oci_services.services[0], "cidr_block")
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Default DHCP Options
resource "oci_core_default_dhcp_options" "this" {
  compartment_id             = var.compartment_id
  display_name               = "${var.display_name_prefix}-DHCP-Options"
  domain_name_type           = "CUSTOM_DOMAIN"
  manage_default_resource_id = oci_core_vcn.this.default_dhcp_options_id

  options {
    type               = "DomainNameServer"
    server_type        = "VcnLocalPlusInternet"
    custom_dns_servers = []
  }

  options {
    type = "SearchDomain"
    search_domain_names = [
      "${var.dns_label}.oraclevcn.com"
    ]
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Default Security List
resource "oci_core_default_security_list" "this" {
  compartment_id             = var.compartment_id
  display_name               = "${var.display_name_prefix}-Default-Security-List"
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id

  # Allow all egress traffic
  egress_security_rules {
    description      = "Allow all outbound traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  # Allow SSH from anywhere (can be restricted as needed)
  ingress_security_rules {
    description = "SSH access"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  # ICMP traffic for path discovery
  ingress_security_rules {
    description = "ICMP Path Discovery"
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    icmp_options {
      type = 3
      code = 4
    }
  }

  # ICMP from VCN
  ingress_security_rules {
    description = "ICMP from VCN"
    protocol    = "1"
    source      = var.vcn_cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = false
    icmp_options {
      type = 3
      code = -1
    }
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

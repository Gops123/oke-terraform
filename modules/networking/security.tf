##############################################################################
# Security Lists for OKE Components
##############################################################################

# Security List for Kubernetes API Endpoint
resource "oci_core_security_list" "k8s_api_endpoint" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.display_name_prefix}-K8S-API-Endpoint-Security-List"

  # Ingress Rules
  # Kubernetes worker to API endpoint communication
  ingress_security_rules {
    description = "Kubernetes worker to API endpoint (port 6443)"
    protocol    = "6"
    source      = var.worker_nodes_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Kubernetes worker to control plane communication
  ingress_security_rules {
    description = "Kubernetes worker to control plane (port 12250)"
    protocol    = "6"
    source      = var.worker_nodes_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  # Path discovery ICMP
  ingress_security_rules {
    description = "Path Discovery ICMP from worker nodes"
    protocol    = "1"
    source      = var.worker_nodes_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    icmp_options {
      type = 3
      code = 4
    }
  }

  # Optional: Bastion to API endpoint (if bastion subnet exists)
  dynamic "ingress_security_rules" {
    for_each = var.create_bastion_subnet ? [1] : []
    content {
      description = "Bastion to Kubernetes API endpoint"
      protocol    = "6"
      source      = var.bastion_subnet_cidr
      source_type = "CIDR_BLOCK"
      stateless   = false
      tcp_options {
        min = 6443
        max = 6443
      }
    }
  }

  # Egress Rules
  # Allow communication with OKE service
  egress_security_rules {
    description      = "Allow API endpoint to communicate with OKE service"
    destination      = lookup(data.oci_core_services.all_oci_services.services[0], "cidr_block")
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
  }

  # Path discovery to OKE service
  egress_security_rules {
    description      = "Path Discovery to OKE service"
    destination      = lookup(data.oci_core_services.all_oci_services.services[0], "cidr_block")
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "1"
    stateless        = false
    icmp_options {
      type = 3
      code = 4
    }
  }

  # Allow communication with worker nodes
  egress_security_rules {
    description      = "Allow API endpoint to communicate with worker nodes"
    destination      = var.worker_nodes_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
  }

  # Path discovery to worker nodes
  egress_security_rules {
    description      = "Path Discovery to worker nodes"
    destination      = var.worker_nodes_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "1"
    stateless        = false
    icmp_options {
      type = 3
      code = 4
    }
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Security List for Worker Nodes
resource "oci_core_security_list" "worker_nodes" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.display_name_prefix}-Worker-Nodes-Security-List"

  # Ingress Rules
  # Allow communication between worker nodes
  ingress_security_rules {
    description = "Allow pods on worker nodes to communicate"
    protocol    = "all"
    source      = var.worker_nodes_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  # Allow API endpoint to communicate with worker nodes
  ingress_security_rules {
    description = "Allow API endpoint to communicate with worker nodes"
    protocol    = "6"
    source      = var.k8s_api_endpoint_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  # Path discovery ICMP
  ingress_security_rules {
    description = "Path Discovery ICMP"
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    icmp_options {
      type = 3
      code = 4
    }
  }

  # SSH access from bastion (if bastion subnet exists)
  dynamic "ingress_security_rules" {
    for_each = var.create_bastion_subnet ? [1] : []
    content {
      description = "SSH access from bastion"
      protocol    = "6"
      source      = var.bastion_subnet_cidr
      source_type = "CIDR_BLOCK"
      stateless   = false
      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  # Load balancer to worker nodes (NodePort range)
  ingress_security_rules {
    description = "Load balancer to worker nodes NodePort TCP"
    protocol    = "6"
    source      = var.load_balancers_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  ingress_security_rules {
    description = "Load balancer to worker nodes NodePort UDP"
    protocol    = "17"
    source      = var.load_balancers_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    udp_options {
      min = 30000
      max = 32767
    }
  }

  # Load balancer to kube-proxy health check
  ingress_security_rules {
    description = "Load balancer to kube-proxy health check"
    protocol    = "6"
    source      = var.load_balancers_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  # Egress Rules
  # Allow communication between worker nodes
  egress_security_rules {
    description      = "Allow communication between worker nodes"
    destination      = var.worker_nodes_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  # Allow communication with OKE service
  egress_security_rules {
    description      = "Allow worker nodes to communicate with OKE service"
    destination      = lookup(data.oci_core_services.all_oci_services.services[0], "cidr_block")
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
  }

  # Allow communication with API endpoint
  egress_security_rules {
    description      = "Worker to API endpoint (port 6443)"
    destination      = var.k8s_api_endpoint_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    description      = "Worker to control plane (port 12250)"
    destination      = var.k8s_api_endpoint_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  # Allow internet access for pulling images
  egress_security_rules {
    description      = "Allow internet access for pulling images"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Security List for Load Balancers
resource "oci_core_security_list" "load_balancers" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.display_name_prefix}-Load-Balancers-Security-List"

  # Ingress Rules
  # HTTP traffic
  ingress_security_rules {
    description = "HTTP traffic from internet"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS traffic
  ingress_security_rules {
    description = "HTTPS traffic from internet"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Custom application ports (configurable)
  dynamic "ingress_security_rules" {
    for_each = var.load_balancer_ingress_ports
    content {
      description = "Custom application port ${ingress_security_rules.value}"
      protocol    = "6"
      source      = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"
      stateless   = false
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  # Egress Rules
  # Load balancer to worker nodes (NodePort range)
  egress_security_rules {
    description      = "Load balancer to worker nodes NodePort TCP"
    destination      = var.worker_nodes_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  # Load balancer to kube-proxy health check
  egress_security_rules {
    description      = "Load balancer to kube-proxy health check"
    destination      = var.worker_nodes_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  # Load balancer to worker nodes UDP
  egress_security_rules {
    description      = "Load balancer to worker nodes NodePort UDP"
    destination      = var.worker_nodes_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "17"
    stateless        = false
    udp_options {
      min = 30000
      max = 32767
    }
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    ignore_changes = [ingress_security_rules, egress_security_rules]
  }
}

# Optional: Security List for Bastion Host
resource "oci_core_security_list" "bastion" {
  count = var.create_bastion_subnet ? 1 : 0
  
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.display_name_prefix}-Bastion-Security-List"

  # Ingress Rules
  # SSH access from allowed CIDRs
  dynamic "ingress_security_rules" {
    for_each = var.bastion_allowed_cidrs
    content {
      description = "SSH access from ${ingress_security_rules.value}"
      protocol    = "6"
      source      = ingress_security_rules.value
      source_type = "CIDR_BLOCK"
      stateless   = false
      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  # Egress Rules
  # SSH to worker nodes
  egress_security_rules {
    description      = "SSH to worker nodes"
    destination      = var.worker_nodes_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTPS to Kubernetes API
  egress_security_rules {
    description      = "HTTPS to Kubernetes API"
    destination      = var.k8s_api_endpoint_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Allow internet access for package updates
  egress_security_rules {
    description      = "Allow internet access"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

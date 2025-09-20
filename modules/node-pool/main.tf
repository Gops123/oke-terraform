##############################################################################
# Node Pool Module - Production Grade
# 
# This module creates:
# - OKE Node Pools with flexible configuration
# - Auto-scaling capabilities
# - Custom shapes and images
# - Node cycling for maintenance
# - Security and tagging
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

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Node Pool
resource "oci_containerengine_node_pool" "this" {
  for_each = var.node_pools

  compartment_id     = var.compartment_id
  cluster_id         = var.cluster_id
  name               = "${var.display_name_prefix}-${each.key}"
  node_shape         = each.value.shape
  kubernetes_version = var.kubernetes_version

  # Initial node labels
  dynamic "initial_node_labels" {
    for_each = each.value.node_labels
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }

  # Node configuration details
  node_config_details {
    # Placement configurations
    dynamic "placement_configs" {
      for_each = each.value.availability_domains
      content {
        availability_domain = placement_configs.value
        subnet_id          = var.worker_subnet_id
        capacity_reservation_id = lookup(each.value, "capacity_reservation_id", null)
        fault_domains      = lookup(each.value, "fault_domains", null)
      }
    }

    size = each.value.size

    # Optional configurations
    is_pv_encryption_in_transit_enabled = lookup(each.value, "pv_encryption_in_transit", false)
    
    # Node pool pod network options (for VCN-Native CNI)
    dynamic "node_pool_pod_network_option_details" {
      for_each = var.cni_type == "OCI_VCN_IP_NATIVE" ? [1] : []
      content {
        cni_type       = var.cni_type
        max_pods_per_node = lookup(each.value, "max_pods_per_node", null)
        pod_subnet_ids = var.pod_subnet_ids != null ? var.pod_subnet_ids : [var.worker_subnet_id]
        pod_nsg_ids    = lookup(each.value, "pod_nsg_ids", [])
      }
    }

    # KMS key for boot volume encryption
    kms_key_id = lookup(each.value, "kms_key_id", null)

  }

  # Node pool cycling details (for rolling updates)
  dynamic "node_pool_cycling_details" {
    for_each = lookup(each.value, "node_cycling", null) != null ? [each.value.node_cycling] : []
    content {
      is_node_cycling_enabled = lookup(node_pool_cycling_details.value, "enabled", false)
      maximum_surge          = lookup(node_pool_cycling_details.value, "maximum_surge", "1")
      maximum_unavailable    = lookup(node_pool_cycling_details.value, "maximum_unavailable", "0")
    }
  }

  # Node shape configuration (for flexible shapes)
  dynamic "node_shape_config" {
    for_each = lookup(each.value, "shape_config", null) != null ? [each.value.shape_config] : []
    content {
      memory_in_gbs = lookup(node_shape_config.value, "memory_in_gbs", null)
      ocpus         = lookup(node_shape_config.value, "ocpus", null)
    }
  }

  # Node source details
  node_source_details {
    image_id    = each.value.image_id
    source_type = "IMAGE"
    
    boot_volume_size_in_gbs = lookup(each.value, "boot_volume_size_gb", 50)
  }

  # SSH public key for node access
  ssh_public_key = lookup(each.value, "ssh_public_key", null)


  # Tagging
  freeform_tags = merge(var.freeform_tags, lookup(each.value, "freeform_tags", {}))
  defined_tags  = merge(var.defined_tags, lookup(each.value, "defined_tags", {}))

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to node configuration to prevent recreation
      node_config_details[0].size,
      kubernetes_version,
    ]
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

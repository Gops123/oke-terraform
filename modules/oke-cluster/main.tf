##############################################################################
# OKE Cluster Module - Production Grade
# 
# This module creates:
# - OKE Cluster with configurable options
# - Cluster add-ons and configuration
# - Proper networking integration
# - Security and compliance features
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

# OKE Cluster
resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "${var.display_name_prefix}-oke-cluster"
  vcn_id             = var.vcn_id
  type               = var.cluster_type

  # Cluster Pod Network Options
  cluster_pod_network_options {
    cni_type = var.cni_type
  }

  # Endpoint Configuration
  endpoint_config {
    is_public_ip_enabled = var.is_api_endpoint_public
    subnet_id            = var.api_endpoint_subnet_id
    nsg_ids              = var.api_endpoint_nsg_ids
  }

  # Image Policy Configuration (for image signing)
  dynamic "image_policy_config" {
    for_each = var.image_signing_enabled ? [1] : []
    content {
      is_policy_enabled = var.image_signing_enabled
      dynamic "key_details" {
        for_each = var.image_signing_key_ids
        content {
          kms_key_id = key_details.value
        }
      }
    }
  }

  # Cluster Configuration Options
  options {
    # Add-ons Configuration
    add_ons {
      is_kubernetes_dashboard_enabled = var.enable_kubernetes_dashboard
      is_tiller_enabled              = var.enable_tiller
    }

    # Kubernetes Network Configuration
    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }

    # Persistent Volume Configuration
    dynamic "persistent_volume_config" {
      for_each = length(var.pv_freeform_tags) > 0 || length(var.pv_defined_tags) > 0 ? [1] : []
      content {
        freeform_tags = var.pv_freeform_tags
        defined_tags  = var.pv_defined_tags
      }
    }

    # Service Load Balancer Configuration
    dynamic "service_lb_config" {
      for_each = length(var.lb_freeform_tags) > 0 || length(var.lb_defined_tags) > 0 ? [1] : []
      content {
        freeform_tags = var.lb_freeform_tags
        defined_tags  = var.lb_defined_tags
      }
    }

    # Load Balancer Subnet IDs
    service_lb_subnet_ids = var.load_balancer_subnet_ids

    # Admission Controller Options
    dynamic "admission_controller_options" {
      for_each = var.enable_pod_security_policy ? [1] : []
      content {
        is_pod_security_policy_enabled = var.enable_pod_security_policy
      }
    }
  }

  # KMS Key for cluster encryption (optional)
  kms_key_id = var.cluster_kms_key_id

  # Tagging
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to these attributes to prevent unintended updates
      kubernetes_version,
    ]
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

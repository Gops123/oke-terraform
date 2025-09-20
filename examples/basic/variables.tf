##############################################################################
# Basic Example Variables
##############################################################################

variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}

variable "region" {
  description = "The OCI region name"
  type        = string
}

variable "compartment_id" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

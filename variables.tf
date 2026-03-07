variable "domain_name" {
  description = "The name of the SageMaker Studio domain."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID for the SageMaker Studio domain."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the SageMaker Studio domain."
  type        = list(string)
}

variable "auth_mode" {
  description = "The authentication mode for the SageMaker Studio domain."
  type        = string
  default     = "IAM"

  validation {
    condition     = contains(["IAM", "SSO"], var.auth_mode)
    error_message = "auth_mode must be either 'IAM' or 'SSO'."
  }
}

variable "app_network_access_type" {
  description = "The network access type for the SageMaker Studio domain."
  type        = string
  default     = "VpcOnly"

  validation {
    condition     = contains(["PublicInternetOnly", "VpcOnly"], var.app_network_access_type)
    error_message = "app_network_access_type must be either 'PublicInternetOnly' or 'VpcOnly'."
  }
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key used to encrypt data at rest."
  type        = string
  default     = null
}

variable "default_user_settings" {
  description = "Default user settings for the SageMaker Studio domain."
  type = object({
    execution_role_arn = optional(string)
    jupyter_server_app_settings = optional(object({
      default_resource_spec = optional(object({
        instance_type        = optional(string, "system")
        lifecycle_config_arn = optional(string)
        sagemaker_image_arn  = optional(string)
      }))
    }))
    kernel_gateway_app_settings = optional(object({
      default_resource_spec = optional(object({
        instance_type        = optional(string, "ml.t3.medium")
        lifecycle_config_arn = optional(string)
        sagemaker_image_arn  = optional(string)
      }))
      custom_images = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })), [])
    }))
  })
  default = {}
}

variable "user_profiles" {
  description = "Map of user profiles to create in the SageMaker Studio domain."
  type = map(object({
    name               = string
    execution_role_arn = optional(string)
    tags               = optional(map(string), {})
  }))
  default = {}
}

variable "spaces" {
  description = "Map of spaces to create in the SageMaker Studio domain."
  type = map(object({
    name = string
    space_settings = optional(object({
      jupyter_server_app_settings = optional(object({
        default_resource_spec = optional(object({
          instance_type       = optional(string, "system")
          sagemaker_image_arn = optional(string)
        }))
      }))
      kernel_gateway_app_settings = optional(object({
        default_resource_spec = optional(object({
          instance_type       = optional(string, "ml.t3.medium")
          sagemaker_image_arn = optional(string)
        }))
      }))
    }))
  }))
  default = {}
}

variable "lifecycle_configs" {
  description = "Map of lifecycle configurations for SageMaker Studio."
  type = map(object({
    name     = string
    content  = string
    app_type = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.lifecycle_configs : contains(["JupyterServer", "KernelGateway"], v.app_type)
    ])
    error_message = "app_type must be either 'JupyterServer' or 'KernelGateway'."
  }
}

variable "custom_images" {
  description = "List of custom SageMaker images to create."
  type = list(object({
    image_name    = string
    image_uri     = string
    role_arn      = optional(string)
    display_name  = optional(string)
    description   = optional(string)
  }))
  default = []
}

variable "enable_efs_encryption" {
  description = "Whether to enable EFS encryption for the SageMaker Studio domain."
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of additional security group IDs to attach to the SageMaker Studio domain."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

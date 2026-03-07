################################################################################
# SageMaker Studio Domain
################################################################################

resource "aws_sagemaker_domain" "this" {
  domain_name             = var.domain_name
  auth_mode               = var.auth_mode
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  app_network_access_type = var.app_network_access_type
  kms_key_id              = var.kms_key_arn

  default_user_settings {
    execution_role  = local.execution_role_arn
    security_groups = local.security_group_ids

    dynamic "jupyter_server_app_settings" {
      for_each = var.default_user_settings.jupyter_server_app_settings != null ? [var.default_user_settings.jupyter_server_app_settings] : []

      content {
        dynamic "default_resource_spec" {
          for_each = jupyter_server_app_settings.value.default_resource_spec != null ? [jupyter_server_app_settings.value.default_resource_spec] : []

          content {
            instance_type        = default_resource_spec.value.instance_type
            lifecycle_config_arn = default_resource_spec.value.lifecycle_config_arn
            sagemaker_image_arn  = default_resource_spec.value.sagemaker_image_arn
          }
        }
      }
    }

    dynamic "kernel_gateway_app_settings" {
      for_each = var.default_user_settings.kernel_gateway_app_settings != null ? [var.default_user_settings.kernel_gateway_app_settings] : []

      content {
        dynamic "default_resource_spec" {
          for_each = kernel_gateway_app_settings.value.default_resource_spec != null ? [kernel_gateway_app_settings.value.default_resource_spec] : []

          content {
            instance_type        = default_resource_spec.value.instance_type
            lifecycle_config_arn = default_resource_spec.value.lifecycle_config_arn
            sagemaker_image_arn  = default_resource_spec.value.sagemaker_image_arn
          }
        }

        dynamic "custom_image" {
          for_each = kernel_gateway_app_settings.value.custom_images

          content {
            app_image_config_name = custom_image.value.app_image_config_name
            image_name            = custom_image.value.image_name
            image_version_number  = custom_image.value.image_version_number
          }
        }
      }
    }
  }

  retention_policy {
    home_efs_file_system = "Delete"
  }

  tags = local.default_tags
}

################################################################################
# SageMaker User Profiles
################################################################################

resource "aws_sagemaker_user_profile" "this" {
  for_each = var.user_profiles

  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = each.value.name

  user_settings {
    execution_role = coalesce(each.value.execution_role_arn, local.execution_role_arn)
  }

  tags = merge(local.default_tags, each.value.tags)
}

################################################################################
# SageMaker Spaces
################################################################################

resource "aws_sagemaker_space" "this" {
  for_each = var.spaces

  domain_id  = aws_sagemaker_domain.this.id
  space_name = each.value.name

  dynamic "space_settings" {
    for_each = each.value.space_settings != null ? [each.value.space_settings] : []

    content {
      dynamic "jupyter_server_app_settings" {
        for_each = space_settings.value.jupyter_server_app_settings != null ? [space_settings.value.jupyter_server_app_settings] : []

        content {
          dynamic "default_resource_spec" {
            for_each = jupyter_server_app_settings.value.default_resource_spec != null ? [jupyter_server_app_settings.value.default_resource_spec] : []

            content {
              instance_type       = default_resource_spec.value.instance_type
              sagemaker_image_arn = default_resource_spec.value.sagemaker_image_arn
            }
          }
        }
      }

      dynamic "kernel_gateway_app_settings" {
        for_each = space_settings.value.kernel_gateway_app_settings != null ? [space_settings.value.kernel_gateway_app_settings] : []

        content {
          dynamic "default_resource_spec" {
            for_each = kernel_gateway_app_settings.value.default_resource_spec != null ? [kernel_gateway_app_settings.value.default_resource_spec] : []

            content {
              instance_type       = default_resource_spec.value.instance_type
              sagemaker_image_arn = default_resource_spec.value.sagemaker_image_arn
            }
          }
        }
      }
    }
  }

  tags = local.default_tags
}

################################################################################
# SageMaker Studio Lifecycle Configs
################################################################################

resource "aws_sagemaker_studio_lifecycle_config" "this" {
  for_each = var.lifecycle_configs

  studio_lifecycle_config_name     = each.value.name
  studio_lifecycle_config_app_type = each.value.app_type
  studio_lifecycle_config_content  = base64encode(each.value.content)

  tags = local.default_tags
}

################################################################################
# SageMaker Custom Images
################################################################################

resource "aws_sagemaker_image" "this" {
  count = length(var.custom_images)

  image_name   = var.custom_images[count.index].image_name
  role_arn     = coalesce(var.custom_images[count.index].role_arn, local.execution_role_arn)
  display_name = var.custom_images[count.index].display_name
  description  = var.custom_images[count.index].description

  tags = local.default_tags
}

resource "aws_sagemaker_image_version" "this" {
  count = length(var.custom_images)

  image_name = aws_sagemaker_image.this[count.index].id
  base_image = var.custom_images[count.index].image_uri
}

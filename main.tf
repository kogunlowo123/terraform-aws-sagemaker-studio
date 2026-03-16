################################################################################
# SageMaker Execution Role
################################################################################

data "aws_iam_policy_document" "sagemaker_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sagemaker_execution_role" {
  name               = "${var.domain_name}-sagemaker-execution-role"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "sagemaker_execution" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::*",
    ]
  }

  statement {
    sid    = "ECRAccess"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "cloudwatch:PutMetricData",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SageMakerAccess"
    effect = "Allow"
    actions = [
      "sagemaker:CreateTrainingJob",
      "sagemaker:CreateModel",
      "sagemaker:CreateEndpoint",
      "sagemaker:CreateEndpointConfig",
      "sagemaker:CreateTransformJob",
      "sagemaker:CreateProcessingJob",
      "sagemaker:DescribeTrainingJob",
      "sagemaker:DescribeModel",
      "sagemaker:DescribeEndpoint",
      "sagemaker:DescribeEndpointConfig",
      "sagemaker:DescribeTransformJob",
      "sagemaker:DescribeProcessingJob",
      "sagemaker:ListTags",
      "sagemaker:AddTags",
      "sagemaker:DeleteTags",
      "sagemaker:Search",
      "sagemaker:ListTrainingJobs",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:sagemaker:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }

  statement {
    sid    = "IAMPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.sagemaker_execution_role.arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["sagemaker.amazonaws.com"]
    }
  }

  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []

    content {
      sid    = "KMSAccess"
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
      ]
      resources = [var.kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "sagemaker_execution" {
  name   = "${var.domain_name}-sagemaker-execution-policy"
  role   = aws_iam_role.sagemaker_execution_role.id
  policy = data.aws_iam_policy_document.sagemaker_execution.json
}

################################################################################
# Security Group for SageMaker Studio
################################################################################

resource "aws_security_group" "studio" {
  name        = "${var.domain_name}-sagemaker-studio-sg"
  description = "Security group for SageMaker Studio domain ${var.domain_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.domain_name}-sagemaker-studio-sg"
  })
}

resource "aws_security_group_rule" "studio_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.studio.id
  description       = "Allow inbound traffic between Studio instances"
}

resource "aws_security_group_rule" "studio_ingress_nfs" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.studio.id
  description       = "Allow NFS traffic for EFS"
}

resource "aws_security_group_rule" "studio_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.studio.id
  description       = "Allow all outbound traffic"
}

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
    execution_role  = var.default_user_settings.execution_role_arn != null ? var.default_user_settings.execution_role_arn : aws_iam_role.sagemaker_execution_role.arn
    security_groups = concat([aws_security_group.studio.id], var.security_group_ids)

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

  tags = var.tags
}

################################################################################
# SageMaker User Profiles
################################################################################

resource "aws_sagemaker_user_profile" "this" {
  for_each = var.user_profiles

  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = each.value.name

  user_settings {
    execution_role = coalesce(each.value.execution_role_arn, var.default_user_settings.execution_role_arn != null ? var.default_user_settings.execution_role_arn : aws_iam_role.sagemaker_execution_role.arn)
  }

  tags = merge(var.tags, each.value.tags)
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

  tags = var.tags
}

################################################################################
# SageMaker Studio Lifecycle Configs
################################################################################

resource "aws_sagemaker_studio_lifecycle_config" "this" {
  for_each = var.lifecycle_configs

  studio_lifecycle_config_name     = each.value.name
  studio_lifecycle_config_app_type = each.value.app_type
  studio_lifecycle_config_content  = base64encode(each.value.content)

  tags = var.tags
}

################################################################################
# SageMaker Custom Images
################################################################################

resource "aws_sagemaker_image" "this" {
  count = length(var.custom_images)

  image_name   = var.custom_images[count.index].image_name
  role_arn     = coalesce(var.custom_images[count.index].role_arn, aws_iam_role.sagemaker_execution_role.arn)
  display_name = var.custom_images[count.index].display_name
  description  = var.custom_images[count.index].description

  tags = var.tags
}

resource "aws_sagemaker_image_version" "this" {
  count = length(var.custom_images)

  image_name = aws_sagemaker_image.this[count.index].id
  base_image = var.custom_images[count.index].image_uri
}

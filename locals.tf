locals {
  execution_role_arn = var.default_user_settings.execution_role_arn != null ? var.default_user_settings.execution_role_arn : aws_iam_role.sagemaker_execution_role.arn

  security_group_ids = concat(
    [aws_security_group.studio.id],
    var.security_group_ids
  )

  default_tags = merge(
    {
      "ManagedBy" = "terraform"
      "Module"    = "terraform-aws-sagemaker-studio"
    },
    var.tags
  )
}

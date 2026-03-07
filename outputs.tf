################################################################################
# SageMaker Studio Domain
################################################################################

output "domain_id" {
  description = "The ID of the SageMaker Studio domain."
  value       = aws_sagemaker_domain.this.id
}

output "domain_arn" {
  description = "The ARN of the SageMaker Studio domain."
  value       = aws_sagemaker_domain.this.arn
}

output "domain_url" {
  description = "The URL of the SageMaker Studio domain."
  value       = aws_sagemaker_domain.this.url
}

output "home_efs_file_system_id" {
  description = "The ID of the EFS file system created for the domain."
  value       = aws_sagemaker_domain.this.home_efs_file_system_id
}

################################################################################
# IAM
################################################################################

output "execution_role_arn" {
  description = "The ARN of the SageMaker execution role."
  value       = aws_iam_role.sagemaker_execution_role.arn
}

output "execution_role_name" {
  description = "The name of the SageMaker execution role."
  value       = aws_iam_role.sagemaker_execution_role.name
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "The ID of the security group created for SageMaker Studio."
  value       = aws_security_group.studio.id
}

################################################################################
# User Profiles
################################################################################

output "user_profile_arns" {
  description = "Map of user profile names to their ARNs."
  value = {
    for k, v in aws_sagemaker_user_profile.this : k => v.arn
  }
}

################################################################################
# Spaces
################################################################################

output "space_arns" {
  description = "Map of space names to their ARNs."
  value = {
    for k, v in aws_sagemaker_space.this : k => v.arn
  }
}

################################################################################
# Lifecycle Configs
################################################################################

output "lifecycle_config_arns" {
  description = "Map of lifecycle config names to their ARNs."
  value = {
    for k, v in aws_sagemaker_studio_lifecycle_config.this : k => v.arn
  }
}

################################################################################
# Custom Images
################################################################################

output "custom_image_arns" {
  description = "List of custom SageMaker image ARNs."
  value       = aws_sagemaker_image.this[*].arn
}

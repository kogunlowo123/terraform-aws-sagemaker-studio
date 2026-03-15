module "test" {
  source = "../"

  domain_name = "test-sagemaker-studio"
  vpc_id      = "vpc-0abc1234def567890"
  subnet_ids  = ["subnet-0abc1234def567890", "subnet-0abc1234def567891"]

  auth_mode               = "IAM"
  app_network_access_type = "VpcOnly"

  enable_efs_encryption = true

  default_user_settings = {
    kernel_gateway_app_settings = {
      default_resource_spec = {
        instance_type = "ml.t3.medium"
      }
    }
  }

  user_profiles = {
    "data-scientist" = {
      name = "test-data-scientist"
      tags = {
        Role = "DataScientist"
      }
    }
  }

  tags = {
    Project     = "sagemaker-studio-test"
    Environment = "test"
  }
}

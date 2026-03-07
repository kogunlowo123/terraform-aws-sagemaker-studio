provider "aws" {
  region = "us-east-1"
}

module "sagemaker_studio" {
  source = "../../"

  domain_name             = "advanced-studio-domain"
  vpc_id                  = "vpc-0123456789abcdef0"
  subnet_ids              = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  auth_mode               = "IAM"
  app_network_access_type = "VpcOnly"
  kms_key_arn             = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  default_user_settings = {
    jupyter_server_app_settings = {
      default_resource_spec = {
        instance_type = "system"
      }
    }
    kernel_gateway_app_settings = {
      default_resource_spec = {
        instance_type = "ml.t3.medium"
      }
    }
  }

  user_profiles = {
    data_scientist = {
      name = "data-scientist-user"
      tags = {
        Role = "DataScientist"
      }
    }
    ml_engineer = {
      name = "ml-engineer-user"
      tags = {
        Role = "MLEngineer"
      }
    }
  }

  lifecycle_configs = {
    install_packages = {
      name     = "install-packages"
      app_type = "KernelGateway"
      content  = <<-EOT
        #!/bin/bash
        set -eux
        pip install --quiet boto3 pandas scikit-learn
      EOT
    }
    jupyter_auto_shutdown = {
      name     = "auto-shutdown-jupyter"
      app_type = "JupyterServer"
      content  = <<-EOT
        #!/bin/bash
        set -eux
        IDLE_TIME=3600
        echo "Setting up auto-shutdown after $IDLE_TIME seconds of inactivity"
      EOT
    }
  }

  tags = {
    Environment = "staging"
    Project     = "ml-platform"
  }
}

output "domain_id" {
  value = module.sagemaker_studio.domain_id
}

output "user_profile_arns" {
  value = module.sagemaker_studio.user_profile_arns
}

output "lifecycle_config_arns" {
  value = module.sagemaker_studio.lifecycle_config_arns
}

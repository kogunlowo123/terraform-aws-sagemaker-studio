provider "aws" {
  region = "us-east-1"
}

module "sagemaker_studio" {
  source = "../../"

  domain_name             = "complete-studio-domain"
  vpc_id                  = "vpc-0123456789abcdef0"
  subnet_ids              = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1", "subnet-0123456789abcdef2"]
  auth_mode               = "IAM"
  app_network_access_type = "VpcOnly"
  kms_key_arn             = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  enable_efs_encryption   = true
  security_group_ids      = ["sg-0123456789abcdef0"]

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
      custom_images = []
    }
  }

  user_profiles = {
    data_scientist = {
      name = "data-scientist"
      tags = {
        Role       = "DataScientist"
        Department = "Research"
      }
    }
    ml_engineer = {
      name = "ml-engineer"
      tags = {
        Role       = "MLEngineer"
        Department = "Engineering"
      }
    }
    analyst = {
      name = "analyst"
      tags = {
        Role       = "Analyst"
        Department = "Analytics"
      }
    }
  }

  spaces = {
    shared_workspace = {
      name = "shared-workspace"
      space_settings = {
        kernel_gateway_app_settings = {
          default_resource_spec = {
            instance_type = "ml.t3.medium"
          }
        }
      }
    }
    experiment_space = {
      name = "experiment-space"
      space_settings = {
        jupyter_server_app_settings = {
          default_resource_spec = {
            instance_type = "system"
          }
        }
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
        pip install --quiet boto3 pandas scikit-learn numpy matplotlib seaborn
      EOT
    }
    configure_git = {
      name     = "configure-git"
      app_type = "KernelGateway"
      content  = <<-EOT
        #!/bin/bash
        set -eux
        git config --global credential.helper '!aws codecommit credential-helper $@'
        git config --global credential.UseHttpPath true
      EOT
    }
    auto_shutdown = {
      name     = "auto-shutdown"
      app_type = "JupyterServer"
      content  = <<-EOT
        #!/bin/bash
        set -eux
        IDLE_TIME=3600
        echo "Auto-shutdown configured for $IDLE_TIME seconds"
      EOT
    }
  }

  custom_images = [
    {
      image_name   = "custom-datascience"
      image_uri    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/custom-datascience:latest"
      display_name = "Custom Data Science"
      description  = "Custom data science image with pre-installed packages"
    }
  ]

  tags = {
    Environment = "production"
    Project     = "ml-platform"
    Team        = "data-science"
    CostCenter  = "ml-ops"
  }
}

output "domain_id" {
  value = module.sagemaker_studio.domain_id
}

output "domain_arn" {
  value = module.sagemaker_studio.domain_arn
}

output "domain_url" {
  value = module.sagemaker_studio.domain_url
}

output "execution_role_arn" {
  value = module.sagemaker_studio.execution_role_arn
}

output "security_group_id" {
  value = module.sagemaker_studio.security_group_id
}

output "user_profile_arns" {
  value = module.sagemaker_studio.user_profile_arns
}

output "space_arns" {
  value = module.sagemaker_studio.space_arns
}

output "lifecycle_config_arns" {
  value = module.sagemaker_studio.lifecycle_config_arns
}

output "custom_image_arns" {
  value = module.sagemaker_studio.custom_image_arns
}

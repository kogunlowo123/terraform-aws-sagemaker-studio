# terraform-aws-sagemaker-studio

Terraform module for provisioning an AWS SageMaker Studio domain with JupyterServer, KernelGateway, VPC-only mode, lifecycle configurations, user profiles, spaces, and custom images.

## Architecture

```mermaid
flowchart TB
    subgraph Domain["SageMaker Studio Domain"]
        DOM["Studio Domain\n(VPC-only Mode)"]
        UP["User Profiles"]
        SP["Shared Spaces"]
        DOM --> UP
        DOM --> SP
    end

    subgraph Apps["Applications"]
        JS["JupyterServer App"]
        KG["KernelGateway App"]
        CI["Custom Images"]
    end

    subgraph Config["Configuration"]
        LC["Lifecycle Configs\n(Startup Scripts)"]
        IAM["Execution Role\n(S3, ECR, CW, SM)"]
    end

    subgraph Network["Networking & Security"]
        VPC["VPC / Subnets"]
        SGR["Security Group\n(NFS/EFS)"]
        KMS["KMS Encryption"]
    end

    subgraph Storage["Storage"]
        EFS["EFS File System\n(Encrypted)"]
        S3["S3 Buckets\n(Data / Artifacts)"]
    end

    UP --> JS
    UP --> KG
    KG --> CI
    JS --> LC
    KG --> LC
    DOM --> IAM
    DOM --> VPC
    VPC --> SGR
    DOM --> KMS
    DOM --> EFS
    IAM --> S3

    style Domain fill:#FF9900,stroke:#FF9900,color:#fff
    style Apps fill:#8C4FFF,stroke:#8C4FFF,color:#fff
    style Config fill:#1A73E8,stroke:#1A73E8,color:#fff
    style Network fill:#DD344C,stroke:#DD344C,color:#fff
    style Storage fill:#3F8624,stroke:#3F8624,color:#fff
    style DOM fill:#FF9900,stroke:#cc7a00,color:#fff
    style UP fill:#FF9900,stroke:#cc7a00,color:#fff
    style SP fill:#FF9900,stroke:#cc7a00,color:#fff
    style JS fill:#8C4FFF,stroke:#6b3dcc,color:#fff
    style KG fill:#8C4FFF,stroke:#6b3dcc,color:#fff
    style CI fill:#8C4FFF,stroke:#6b3dcc,color:#fff
    style LC fill:#1A73E8,stroke:#1459b3,color:#fff
    style IAM fill:#1A73E8,stroke:#1459b3,color:#fff
    style VPC fill:#DD344C,stroke:#b02a3d,color:#fff
    style SGR fill:#DD344C,stroke:#b02a3d,color:#fff
    style KMS fill:#DD344C,stroke:#b02a3d,color:#fff
    style EFS fill:#3F8624,stroke:#2d6119,color:#fff
    style S3 fill:#3F8624,stroke:#2d6119,color:#fff
```

## Features

- SageMaker Studio Domain with VPC-only network access
- IAM and SSO authentication modes
- Default user settings for JupyterServer and KernelGateway apps
- User profile management
- Shared spaces
- Studio lifecycle configurations
- Custom SageMaker images
- IAM execution role with S3, ECR, CloudWatch, and SageMaker permissions
- Security group for Studio with NFS/EFS support
- KMS encryption support
- EFS encryption

## Usage

### Basic

```hcl
module "sagemaker_studio" {
  source = "terraform-aws-sagemaker-studio"

  domain_name = "my-studio-domain"
  vpc_id      = "vpc-0123456789abcdef0"
  subnet_ids  = ["subnet-0123456789abcdef0"]

  tags = {
    Environment = "dev"
  }
}
```

### With User Profiles and Lifecycle Configs

```hcl
module "sagemaker_studio" {
  source = "terraform-aws-sagemaker-studio"

  domain_name = "my-studio-domain"
  vpc_id      = "vpc-0123456789abcdef0"
  subnet_ids  = ["subnet-0123456789abcdef0"]

  user_profiles = {
    data_scientist = {
      name = "data-scientist"
      tags = { Role = "DataScientist" }
    }
  }

  lifecycle_configs = {
    install_packages = {
      name     = "install-packages"
      app_type = "KernelGateway"
      content  = "#!/bin/bash\npip install pandas scikit-learn"
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.20.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| domain_name | The name of the SageMaker Studio domain | string | n/a | yes |
| vpc_id | The VPC ID for the SageMaker Studio domain | string | n/a | yes |
| subnet_ids | List of subnet IDs for the domain | list(string) | n/a | yes |
| auth_mode | Authentication mode (IAM or SSO) | string | "IAM" | no |
| app_network_access_type | Network access type | string | "VpcOnly" | no |
| kms_key_arn | KMS key ARN for encryption | string | null | no |
| default_user_settings | Default user settings object | object | {} | no |
| user_profiles | Map of user profiles to create | map(object) | {} | no |
| spaces | Map of spaces to create | map(object) | {} | no |
| lifecycle_configs | Map of lifecycle configurations | map(object) | {} | no |
| custom_images | List of custom SageMaker images | list(object) | [] | no |
| enable_efs_encryption | Enable EFS encryption | bool | true | no |
| security_group_ids | Additional security group IDs | list(string) | [] | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| domain_id | The ID of the SageMaker Studio domain |
| domain_arn | The ARN of the SageMaker Studio domain |
| domain_url | The URL of the SageMaker Studio domain |
| home_efs_file_system_id | The EFS file system ID for the domain |
| execution_role_arn | The ARN of the SageMaker execution role |
| execution_role_name | The name of the SageMaker execution role |
| security_group_id | The security group ID for Studio |
| user_profile_arns | Map of user profile ARNs |
| space_arns | Map of space ARNs |
| lifecycle_config_arns | Map of lifecycle config ARNs |
| custom_image_arns | List of custom image ARNs |

## Examples

- [Basic](examples/basic/) - Minimal SageMaker Studio domain
- [Advanced](examples/advanced/) - Domain with user profiles and lifecycle configs
- [Complete](examples/complete/) - Full-featured domain with all options

## License

MIT License. See [LICENSE](LICENSE) for details.

provider "aws" {
  region = "us-east-1"
}

module "sagemaker_studio" {
  source = "../../"

  domain_name = "basic-studio-domain"
  vpc_id      = "vpc-0123456789abcdef0"
  subnet_ids  = ["subnet-0123456789abcdef0"]

  tags = {
    Environment = "dev"
    Project     = "ml-platform"
  }
}

output "domain_id" {
  value = module.sagemaker_studio.domain_id
}

output "domain_url" {
  value = module.sagemaker_studio.domain_url
}

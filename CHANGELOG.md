# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-07

### Added

- SageMaker Studio Domain with VPC-only network access mode
- IAM and SSO authentication mode support
- Default user settings for JupyterServer and KernelGateway applications
- User profile management with per-profile execution roles and tags
- Shared spaces with configurable settings
- Studio lifecycle configurations for JupyterServer and KernelGateway
- Custom SageMaker image and image version resources
- IAM execution role with S3, ECR, CloudWatch, and SageMaker permissions
- Security group for Studio domain with NFS/EFS ingress rules
- KMS encryption support for data at rest
- EFS encryption toggle
- Examples for basic, advanced, and complete usage patterns

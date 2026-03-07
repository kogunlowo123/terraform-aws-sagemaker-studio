################################################################################
# Security Group for SageMaker Studio
################################################################################

resource "aws_security_group" "studio" {
  name        = "${var.domain_name}-sagemaker-studio-sg"
  description = "Security group for SageMaker Studio domain ${var.domain_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    local.default_tags,
    {
      Name = "${var.domain_name}-sagemaker-studio-sg"
    }
  )
}

# Allow all inbound traffic within the security group (NFS for EFS, etc.)
resource "aws_security_group_rule" "studio_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.studio.id
  description       = "Allow inbound traffic between Studio instances"
}

# Allow NFS traffic for EFS (port 2049)
resource "aws_security_group_rule" "studio_ingress_nfs" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.studio.id
  description       = "Allow NFS traffic for EFS"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "studio_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.studio.id
  description       = "Allow all outbound traffic"
}

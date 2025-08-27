# -------------------------------------------------------------------
# Bastion Security Group
# -------------------------------------------------------------------
# Purpose:
# - Allow SSH (port 22) to the bastion host from a specific CIDR you provide.
# - Allow ALL outbound traffic so the bastion can update packages
#   and reach RDS (and other services) as needed.
#
# Notes:
# - We use a *dynamic ingress* block so that if `allowed_ssh_cidr` is an
#   empty string, NO SSH rule is created (safer by default).
# - If you want to allow SSH from anywhere for testing, set
#   allowed_ssh_cidr = "0.0.0.0/0" (⚠️ not recommended for production).
# -------------------------------------------------------------------
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "SSH from user IP and egress all"
  vpc_id      = var.vpc_id

  # Conditionally create SSH ingress only when a non-empty CIDR is provided
  dynamic "ingress" {
    for_each = length(var.allowed_ssh_cidr) > 0 ? [var.allowed_ssh_cidr] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]  # e.g., ["203.0.113.5/32"] or ["0.0.0.0/0"]
    }
  }

  # Allow all outbound so the bastion can reach the internet/RDS/etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-bastion-sg" })
}

# -------------------------------------------------------------------
# RDS Security Group
# -------------------------------------------------------------------
# Purpose:
# - This SG will be attached to the RDS instance.
# - No ingress rules are defined here directly; instead, we attach a
#   separate *security_group_rule* below to allow MySQL *only* from
#   the bastion SG. This keeps intent very clear and least-privilege.
#
# - Egress is open so the database can communicate out if AWS needs it
#   (e.g., to KMS/monitoring endpoints). RDS typically controls its own
#   egress paths, but allowing egress "-1" is a common, simple default.
# -------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "MySQL access only from bastion"
  vpc_id      = var.vpc_id

  # Open egress to anywhere (no ports restricted).
  # This is standard/simple; tighten further if you have strict egress policies.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-rds-sg" })
}

# -------------------------------------------------------------------
# Allow MySQL (3306) to RDS *only* from the Bastion SG
# -------------------------------------------------------------------
# Purpose:
# - Enforce that database connections must come via the bastion instance,
#   not directly from arbitrary IPs on the internet.
# - By referencing the bastion SG as the *source*, we avoid brittle IP-based
#   rules and keep the policy identity-based (infrastructure-friendly).
# -------------------------------------------------------------------
resource "aws_security_group_rule" "rds_from_bastion" {
  type                     = "ingress"
  description              = "MySQL from bastion"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.bastion.id
}

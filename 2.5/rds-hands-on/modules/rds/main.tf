# -------------------------------------------------------------------
# DB Subnet Group
# -------------------------------------------------------------------
# A DB subnet group tells RDS which subnets it can use.
# - We provide the two private subnet IDs from the network module.
# - This ensures the RDS instance is placed only in private subnets
#   (no direct internet access).
# -------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.project_name}-db-subnets" })
}

# -------------------------------------------------------------------
# RDS MySQL Database Instance
# -------------------------------------------------------------------
# This resource creates the actual RDS MySQL instance.
#
# Key points:
# - identifier: a unique name for the instance
# - engine: "mysql" (could be postgres, etc.)
# - instance_class: "db.t3.micro" (free-tier eligible, cheap for labs)
# - allocated_storage: 20 GB, minimum required
# - storage_type: gp3 (modern general-purpose SSD)
# - multi_az: false (keeps costs lower, no standby replica)
# - publicly_accessible: false (private DB, only accessible via bastion)
# - db_subnet_group_name: ties it to our two private subnets
# - vpc_security_group_ids: enforces network access via the RDS SG
#
# Authentication:
# - username: "admin"
# - manage_master_user_password = true → password is auto-generated
#   and stored in Secrets Manager (Terraform never stores it).
#
# Cleanup:
# - deletion_protection = false → allows terraform destroy
# - skip_final_snapshot = true → skip backup when deleting (lab use only)
#
# Extras:
# - backup_retention_period = 1 (minimum for backups)
# - apply_immediately = true → apply changes right away (not wait for window)
# -------------------------------------------------------------------
resource "aws_db_instance" "db" {
  identifier                  = "${var.project_name}-mysql"
  engine                      = "mysql"
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  storage_type                = "gp3"
  multi_az                    = false
  publicly_accessible         = false
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [var.rds_sg_id]

  username                    = "admin"
  manage_master_user_password = true

  deletion_protection         = false
  skip_final_snapshot         = true

  backup_retention_period     = 1
  apply_immediately           = true

  tags = merge(var.tags, { Name = "${var.project_name}-mysql" })
}

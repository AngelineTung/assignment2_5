# -------------------------------------------------------------------



# -------------------------------------------------------------------
# User Data: Initialize the bastion with packages/tools on first boot.
# -------------------------------------------------------------------
# Purpose:
# - Updates the OS packages.
# - Installs the MariaDB client (`mariadb105`) which provides `mysql`,
#   letting you connect to RDS from the bastion.
# - Drops a small marker file so you can confirm the script ran.
# Why:
# - Ensures the bastion is immediately useful for DB connectivity checks.
# -------------------------------------------------------------------
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y mariadb105
    echo "Bastion ready" > /var/log/bastion-ready.log
  EOF
}

# -------------------------------------------------------------------
# EC2 Instance: Bastion host in the public subnet.
# -------------------------------------------------------------------
# Purpose:
# - Launch a small t3.micro in the public subnet with a public IP.
# - Attach the bastion security group (SSH from your CIDR).
# - Inject the user_data to install the MySQL client automatically.
# - If a key pair was created, use it; else leave null and rely on EC2 Connect.
# Why:
# - Provides a controlled entry point into the private network to reach RDS.
# - Keeps costs low (t3.micro), suitable for labs.
# -------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                          = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true
  user_data                   = local.user_data

  
   # Use the existing AWS key pair name (without trying to import via Terraform)
  key_name = var.ssh_public_key   # key name in AWS (your .pem is test.pem)

  tags = merge(var.tags, { Name = "${var.project_name}-bastion" })
}

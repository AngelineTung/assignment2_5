variable "region" {
  description = "AWS region, e.g. us-east-1"
  type        = string
}

variable "profile" {
  description = "AWS CLI profile (e.g. 'default'). Use empty string to rely on env credentials."
  type        = string
}

variable "project_name" {
  description = "Name/tag prefix for resources"
  type        = string
}


variable "ami_id" {
  description = "Optional AMI ID override for the bastion host"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR for VPC, e.g. 10.20.0.0/16"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet, e.g. 10.20.0.0/24"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "Exactly two private subnet CIDRs in different AZs, e.g. [\"10.20.10.0/24\", \"10.20.11.0/24\"]"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Provide exactly two private subnet CIDRs."
  }
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in /32 to allow SSH into bastion, e.g. 203.0.113.5/32"
  type        = string
  validation {
    condition     = length(var.allowed_ssh_cidr) > 0
    error_message = "allowed_ssh_cidr must be a non-empty /32 CIDR (e.g. 203.0.113.5/32)."
  }
}

variable "ssh_public_key" {
  description = "Your SSH public key (optional). Leave empty string to skip keypair and use EC2 Instance Connect."
  type        = string
}

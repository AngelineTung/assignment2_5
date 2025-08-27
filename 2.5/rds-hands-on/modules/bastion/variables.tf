variable "project_name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "ami_id" {
  description = "AMI ID to use for the bastion (optional override)"
  type        = string
  default     = ""
}
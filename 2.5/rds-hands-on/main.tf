locals {
  tags = {
    Project = var.project_name
    Managed = "terraform"
  }
}

module "network" {
  source               = "./modules/network"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.tags
}

module "security" {
  source           = "./modules/security"
  vpc_id           = module.network.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
  project_name     = var.project_name
  tags             = local.tags
}

module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  private_subnet_ids = module.network.private_subnet_ids
  rds_sg_id          = module.security.rds_sg_id
  tags               = local.tags
}

module "bastion" {
  source           = "./modules/bastion"
  project_name     = var.project_name
  public_subnet_id = module.network.public_subnet_id
  bastion_sg_id    = module.security.bastion_sg_id
  ssh_public_key   = var.ssh_public_key
  ami_id           = var.ami_id 
  tags             = local.tags
}

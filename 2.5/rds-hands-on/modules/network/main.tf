# -------------------------------------------------------------------
# Query AWS to fetch all availability zones (AZs) in the selected region.
# We’ll use this to spread resources across multiple AZs.
# -------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# -------------------------------------------------------------------
# Local variable: pick the first two AZs from the list.
# Reason: RDS subnet groups require at least 2 AZs for high availability.
# -------------------------------------------------------------------
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# -------------------------------------------------------------------
# Create the VPC (Virtual Private Cloud).
# - var.vpc_cidr defines the private IP range (e.g. 10.20.0.0/16).
# - enable_dns_support and enable_dns_hostnames let instances use DNS.
# -------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.project_name}-vpc" })
}

# -------------------------------------------------------------------
# Create an Internet Gateway (IGW) and attach it to the VPC.
# Required for outbound internet access from resources in the public subnet.
# -------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.project_name}-igw" })
}

# -------------------------------------------------------------------
# Public subnet – used for the Bastion host.
# - map_public_ip_on_launch = true ensures new instances get public IPs.
# - Placed in the first AZ.
# -------------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "${var.project_name}-public" })
}

# -------------------------------------------------------------------
# Private subnets – used for RDS.
# - Creates two subnets (a, b) in two AZs for HA.
# - No public IPs assigned.
# -------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = {
    a = { cidr = var.private_subnet_cidrs[0], az = local.azs[0] }
    b = { cidr = var.private_subnet_cidrs[1], az = local.azs[1] }
  }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, { Name = "${var.project_name}-private-${each.key}" })
}

# -------------------------------------------------------------------
# Public route table – applies to the public subnet only.
# -------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.project_name}-public-rt" })
}

# -------------------------------------------------------------------
# Add a default route to the Internet Gateway (0.0.0.0/0 → IGW).
# This ensures instances in the public subnet can reach the internet.
# -------------------------------------------------------------------
resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# -------------------------------------------------------------------
# Associate the public subnet with the public route table.
# Without this, the subnet won’t know how to reach the internet.
# -------------------------------------------------------------------
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# Module Composition Lab
# Demonstrates output chaining between terraform-aws-modules:
#   VPC outputs -> Security Group inputs
#   VPC outputs -> EC2 inputs
#   Security Group outputs -> EC2 inputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VPC Module
# Creates a VPC with 2 public and 2 private subnets across 2 AZs.
# This is the foundation module -- its outputs feed into everything else.
# Registry: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws
# -----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  # NAT Gateway configuration -- single NAT for cost savings in a lab
  enable_nat_gateway = true
  single_nat_gateway = true

  # DNS support required for instances to resolve public hostnames
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tag subnets for visibility
  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }

  tags = {
    Module = "vpc"
  }
}

# -----------------------------------------------------------------------------
# Security Group Module
# Creates a security group for the web server with HTTP, HTTPS, and SSH rules.
# Uses module.vpc.vpc_id to place the SG in the correct VPC.
# Registry: https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws
# -----------------------------------------------------------------------------
module "web_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project_name}-web-sg"
  description = "Security group for web server - allows HTTP, HTTPS, and SSH"

  # OUTPUT CHAINING: VPC module output -> Security Group input
  vpc_id = module.vpc.vpc_id

  # Ingress rules using predefined rule sets from the module
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from anywhere"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from anywhere"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from allowed CIDRs"
      cidr_blocks = join(",", var.allowed_ssh_cidrs)
    },
  ]

  # Egress: allow all outbound traffic
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Module = "security-group"
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance Module
# Launches a web server in the first public subnet, attached to the web SG.
# Demonstrates chaining outputs from BOTH the VPC and SG modules.
# Registry: https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws
# -----------------------------------------------------------------------------
module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "${var.project_name}-web"

  ami           = var.instance_ami
  instance_type = var.instance_type
  key_name      = var.key_name

  # OUTPUT CHAINING: VPC module output -> EC2 input
  # Place the instance in the first public subnet from the VPC module
  subnet_id = module.vpc.public_subnets[0]

  # OUTPUT CHAINING: Security Group module output -> EC2 input
  # Attach the security group created by the SG module
  vpc_security_group_ids = [module.web_sg.security_group_id]

  # Associate a public IP so the instance is reachable from the internet
  associate_public_ip_address = true

  # User data script to install and start a basic web server
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from Terraform AWS Modules Lab</h1>" > /var/www/html/index.html
    echo "<p>Instance deployed in: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>" >> /var/www/html/index.html
  EOF

  tags = {
    Module = "ec2-instance"
    Role   = "web-server"
  }
}

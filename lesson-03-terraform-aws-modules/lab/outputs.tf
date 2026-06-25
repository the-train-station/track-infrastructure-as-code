# -----------------------------------------------------------------------------
# VPC Module Outputs
# These values are also consumed internally by the SG and EC2 modules above.
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "nat_gateway_ip" {
  description = "Public IP of the NAT gateway"
  value       = module.vpc.nat_public_ips
}

# -----------------------------------------------------------------------------
# Security Group Module Outputs
# The security_group_id is consumed by the EC2 module above.
# -----------------------------------------------------------------------------

output "web_security_group_id" {
  description = "The ID of the web server security group"
  value       = module.web_sg.security_group_id
}

output "web_security_group_name" {
  description = "The name of the web server security group"
  value       = module.web_sg.security_group_name
}

# -----------------------------------------------------------------------------
# EC2 Module Outputs
# Final outputs from the composed stack.
# -----------------------------------------------------------------------------

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.ec2.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = module.ec2.public_dns
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${module.ec2.public_dns}"
}

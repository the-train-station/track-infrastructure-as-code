variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed SSH access (empty disables SSH)"
  type        = list(string)
  default     = []
}

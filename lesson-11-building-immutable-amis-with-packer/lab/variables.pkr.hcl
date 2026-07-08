variable "region" {
  type        = string
  description = "AWS region to build and register the AMI in."
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type used for the temporary Packer build instance."
  default     = "t3.micro"
}

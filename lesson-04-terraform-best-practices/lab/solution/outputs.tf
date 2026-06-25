output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "web_instance_ids" {
  description = "Map of web server instance IDs"
  value       = module.compute.instance_ids
}

output "web_instance_private_ips" {
  description = "Map of web server private IP addresses"
  value       = module.compute.instance_private_ips
}

output "db_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = module.database.endpoint
}

output "db_name" {
  description = "Name of the database"
  value       = module.database.db_name
}

output "s3_bucket_name" {
  description = "Name of the application assets S3 bucket"
  value       = aws_s3_bucket.assets.id
}

output "s3_bucket_arn" {
  description = "ARN of the application assets S3 bucket"
  value       = aws_s3_bucket.assets.arn
}

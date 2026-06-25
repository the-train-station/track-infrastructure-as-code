output "instance_ids" {
  description = "Map of instance name to instance ID"
  value       = { for k, v in aws_instance.web : k => v.id }
}

output "instance_private_ips" {
  description = "Map of instance name to private IP address"
  value       = { for k, v in aws_instance.web : k => v.private_ip }
}

output "log_group_arn" {
  description = "ARN of the application CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.arn
}

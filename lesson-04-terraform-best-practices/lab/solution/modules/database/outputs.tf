output "endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.this.db_name
}

output "instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
}

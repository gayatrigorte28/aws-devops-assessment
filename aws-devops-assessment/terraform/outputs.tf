output "vpc_id" {
  description = "VPC identifier"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet identifiers"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private application subnet identifiers"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "Private database subnet identifiers"
  value       = aws_subnet.private_db[*].id
}

output "alb_dns_name" {
  description = "ALB DNS name when ALB is enabled"
  value       = try(aws_lb.app[0].dns_name, null)
}

output "database_endpoint" {
  description = "RDS endpoint when database is enabled"
  value       = try(aws_db_instance.main[0].address, null)
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.taskmanager.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.taskmanager.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.taskmanager.name
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.taskmanager.dns_name
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.taskmanager.name
}

# Uncomment if using RDS
# output "database_endpoint" {
#   description = "Endpoint of the RDS database"
#   value       = module.rds.db_instance_endpoint
# }
# 
# output "database_name" {
#   description = "Name of the database"
#   value       = module.rds.db_instance_name
# }

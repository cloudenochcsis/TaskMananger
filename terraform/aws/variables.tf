variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "taskmanager"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "task_cpu" {
  description = "CPU units for the ECS task (1024 = 1 vCPU)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the ECS task in MiB"
  type        = string
  default     = "512"
}

variable "service_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "service_min_count" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "service_max_count" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "secret_key" {
  description = "Secret key for Flask application"
  type        = string
  sensitive   = true
}

# Database variables (uncomment if using RDS)
# variable "db_username" {
#   description = "Username for the database"
#   type        = string
#   sensitive   = true
# }
# 
# variable "db_password" {
#   description = "Password for the database"
#   type        = string
#   sensitive   = true
# }

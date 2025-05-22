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

variable "location" {
  description = "Azure region to deploy to"
  type        = string
  default     = "eastus"
}

variable "container_cpu" {
  description = "CPU cores for the container (0.25, 0.5, 0.75, 1.0, etc.)"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory for the container in GB (0.5, 1.0, 1.5, etc.)"
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum number of container replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of container replicas"
  type        = number
  default     = 3
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "secret_key" {
  description = "Secret key for Flask application"
  type        = string
  sensitive   = true
}

# Uncomment if using Azure SQL Database
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

# Uncomment if using Service Principal for authentication
# variable "subscription_id" {
#   description = "Azure Subscription ID"
#   type        = string
# }
# 
# variable "tenant_id" {
#   description = "Azure Tenant ID"
#   type        = string
# }
# 
# variable "client_id" {
#   description = "Azure Client ID (Service Principal)"
#   type        = string
# }
# 
# variable "client_secret" {
#   description = "Azure Client Secret (Service Principal)"
#   type        = string
#   sensitive   = true
# }

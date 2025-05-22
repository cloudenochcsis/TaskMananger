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

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "app_region" {
  description = "Region for the App Platform deployment"
  type        = string
  default     = "nyc"
}

variable "registry_region" {
  description = "Region for the Container Registry"
  type        = string
  default     = "nyc1"
}

variable "instance_size" {
  description = "Size of the App Platform instance"
  type        = string
  default     = "basic-xs"
}

variable "instance_count" {
  description = "Number of App Platform instances"
  type        = number
  default     = 1
}

variable "github_repo" {
  description = "GitHub repository for the application (format: username/repo)"
  type        = string
  default     = "cloudenochcsis/TaskMananger"
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

variable "secret_key" {
  description = "Secret key for Flask application"
  type        = string
  sensitive   = true
}

# Variables for managed database (uncomment to use)
# variable "use_managed_db" {
#   description = "Whether to use a managed database"
#   type        = bool
#   default     = false
# }
# 
# variable "db_size" {
#   description = "Size of the database cluster"
#   type        = string
#   default     = "db-s-1vcpu-1gb"
# }

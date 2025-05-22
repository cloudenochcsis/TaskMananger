terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  
  # Uncomment this block to use Terraform Cloud for state management
  # backend "remote" {
  #   organization = "your-organization"
  #   workspaces {
  #     name = "taskmanager-digitalocean"
  #   }
  # }
}

provider "digitalocean" {
  token = var.do_token
}

# Container Registry
resource "digitalocean_container_registry" "taskmanager" {
  name                   = "${var.project_name}-registry"
  subscription_tier_slug = "basic"
  region                 = var.registry_region
}

# App Platform Specification
resource "digitalocean_app" "taskmanager" {
  spec {
    name   = "${var.project_name}-${var.environment}"
    region = var.app_region
    
    # Web Service
    service {
      name               = "web"
      instance_count     = var.instance_count
      instance_size_slug = var.instance_size
      
      # Use either GitHub or Container Registry as the source
      # Option 1: GitHub source
      github {
        repo           = var.github_repo
        branch         = var.github_branch
        deploy_on_push = true
      }
      
      # Option 2: Container Registry (uncomment to use)
      # image {
      #   registry_type = "DOCR"
      #   repository    = "${digitalocean_container_registry.taskmanager.name}/taskmanager"
      #   tag           = "latest"
      # }
      
      build_command = "pip install -r TaskManager/requirements.txt"
      run_command   = "gunicorn --workers 4 --threads 2 --bind 0.0.0.0:$PORT TaskManager.app:app"
      
      # Environment Variables
      env {
        key   = "FLASK_APP"
        value = "TaskManager/app.py"
      }
      
      env {
        key   = "FLASK_ENV"
        value = var.environment == "production" ? "production" : "development"
      }
      
      env {
        key   = "SECRET_KEY"
        value = var.secret_key
        type  = "SECRET"
      }
      
      env {
        key   = "DATABASE"
        value = "/app/instance/task_manager.sqlite"
      }
      
      # Health Check
      health_check {
        http_path             = "/"
        initial_delay_seconds = 30
        period_seconds        = 60
      }
      
      # Routes
      routes {
        path = "/"
      }
    }
    
    # Optional: Database (uncomment to use)
    # database {
    #   name       = "taskmanager-db"
    #   engine     = "PG"
    #   production = var.environment == "production"
    #   cluster_name = "taskmanager-${var.environment}-db-cluster"
    #   db_name    = "taskmanager"
    #   db_user    = "dbuser"
    # }
  }
}

# Optional: Managed PostgreSQL Database (uncomment to use)
# resource "digitalocean_database_cluster" "postgres" {
#   name       = "${var.project_name}-${var.environment}-db"
#   engine     = "pg"
#   version    = "14"
#   size       = var.db_size
#   region     = var.app_region
#   node_count = var.environment == "production" ? 2 : 1
# }
# 
# resource "digitalocean_database_db" "taskmanager_db" {
#   cluster_id = digitalocean_database_cluster.postgres.id
#   name       = "taskmanager"
# }
# 
# resource "digitalocean_database_user" "taskmanager_user" {
#   cluster_id = digitalocean_database_cluster.postgres.id
#   name       = "taskmanager"
# }
# 
# # Update the app to use the database
# resource "digitalocean_app" "taskmanager_with_db" {
#   count = var.use_managed_db ? 1 : 0
#   
#   spec {
#     name   = "${var.project_name}-${var.environment}"
#     region = var.app_region
#     
#     # Web Service
#     service {
#       # ... same as above ...
#       
#       # Add database connection env var
#       env {
#         key   = "DATABASE_URL"
#         value = "${digitalocean_database_cluster.postgres.uri}"
#         type  = "SECRET"
#       }
#     }
#     
#     # Link to the database
#     database {
#       name          = digitalocean_database_cluster.postgres.name
#       engine        = "PG"
#       production    = true
#       cluster_name  = digitalocean_database_cluster.postgres.name
#       db_name       = digitalocean_database_db.taskmanager_db.name
#       db_user       = digitalocean_database_user.taskmanager_user.name
#     }
#   }
# }

# Project to organize resources
resource "digitalocean_project" "taskmanager" {
  name        = "${var.project_name}-${var.environment}"
  description = "TaskManager application for ${var.environment} environment"
  purpose     = "Web Application"
  environment = var.environment == "production" ? "Production" : "Development"
  
  resources = [
    digitalocean_app.taskmanager.app_url
  ]
}

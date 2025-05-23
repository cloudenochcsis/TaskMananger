terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  
  # Uncomment this block to use Terraform Cloud for state management
  # backend "remote" {
  #   organization = "your-organization"
  #   workspaces {
  #     name = "taskmanager-azure"
  #   }
  # }
}

provider "azurerm" {
  features {}
  
  # Add subscription_id, tenant_id, client_id, client_secret if using service principal
  # subscription_id = var.subscription_id
  # tenant_id       = var.tenant_id
  # client_id       = var.client_id
  # client_secret   = var.client_secret
}

# Resource Group
resource "azurerm_resource_group" "taskmanager" {
  name     = "${var.project_name}-rg-${var.environment}"
  location = var.location
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Container Registry
resource "azurerm_container_registry" "taskmanager" {
  name                = "${var.project_name}acr${var.environment}"
  resource_group_name = azurerm_resource_group.taskmanager.name
  location            = azurerm_resource_group.taskmanager.location
  sku                 = "Basic"
  admin_enabled       = true
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "taskmanager" {
  name                = "${var.project_name}-logs-${var.environment}"
  resource_group_name = azurerm_resource_group.taskmanager.name
  location            = azurerm_resource_group.taskmanager.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Container Apps Environment
resource "azurerm_container_app_environment" "taskmanager" {
  name                       = "${var.project_name}-env-${var.environment}"
  resource_group_name        = azurerm_resource_group.taskmanager.name
  location                   = azurerm_resource_group.taskmanager.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.taskmanager.id
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Container App
resource "azurerm_container_app" "taskmanager" {
  name                         = "${var.project_name}-app-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.taskmanager.id
  resource_group_name          = azurerm_resource_group.taskmanager.name
  revision_mode                = "Single"
  
  template {
    container {
      name   = "taskmanager"
      image  = "${azurerm_container_registry.taskmanager.login_server}/taskmanager:latest"
      cpu    = var.container_cpu
      memory = var.container_memory
      
      env {
        name  = "FLASK_APP"
        value = "TaskManager/app.py"
      }
      
      env {
        name  = "FLASK_ENV"
        value = var.environment == "production" ? "production" : "development"
      }
      
      env {
        name  = "SECRET_KEY"
        value = var.secret_key
      }
      
      env {
        name  = "DATABASE"
        value = "/app/instance/task_manager.sqlite"
      }
    }
    
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }
  
  ingress {
    external_enabled = true
    target_port      = 5000
    transport        = "http"
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  
  registry {
    server               = azurerm_container_registry.taskmanager.login_server
    username             = azurerm_container_registry.taskmanager.admin_username
    password_secret_name = "registry-password"
  }
  
  secret {
    name  = "registry-password"
    value = azurerm_container_registry.taskmanager.admin_password
  }
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Optional: Azure SQL Database (Uncomment to use)
# resource "azurerm_mssql_server" "taskmanager" {
#   name                         = "${var.project_name}-sql-${var.environment}"
#   resource_group_name          = azurerm_resource_group.taskmanager.name
#   location                     = azurerm_resource_group.taskmanager.location
#   version                      = "12.0"
#   administrator_login          = var.db_username
#   administrator_login_password = var.db_password
#   
#   tags = {
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }
# 
# resource "azurerm_mssql_database" "taskmanager" {
#   name           = "${var.project_name}db"
#   server_id      = azurerm_mssql_server.taskmanager.id
#   collation      = "SQL_Latin1_General_CP1_CI_AS"
#   license_type   = "LicenseIncluded"
#   sku_name       = "S0"
#   zone_redundant = false
#   
#   tags = {
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }
# 
# resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
#   name             = "AllowAzureServices"
#   server_id        = azurerm_mssql_server.taskmanager.id
#   start_ip_address = "0.0.0.0"
#   end_ip_address   = "0.0.0.0"
# }

# Application Insights for monitoring
resource "azurerm_application_insights" "taskmanager" {
  name                = "${var.project_name}-insights-${var.environment}"
  location            = azurerm_resource_group.taskmanager.location
  resource_group_name = azurerm_resource_group.taskmanager.name
  application_type    = "web"
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Optional: Azure Container Instance (Uncomment to use instead of Container Apps)
# resource "azurerm_container_group" "taskmanager" {
#   name                = "${var.project_name}-container-${var.environment}"
#   location            = azurerm_resource_group.taskmanager.location
#   resource_group_name = azurerm_resource_group.taskmanager.name
#   ip_address_type     = "Public"
#   dns_name_label      = "${var.project_name}-${var.environment}"
#   os_type             = "Linux"
#   
#   container {
#     name   = "taskmanager"
#     image  = "${azurerm_container_registry.taskmanager.login_server}/taskmanager:latest"
#     cpu    = var.container_cpu
#     memory = var.container_memory
#     
#     ports {
#       port     = 5000
#       protocol = "TCP"
#     }
#     
#     environment_variables = {
#       "FLASK_APP"  = "TaskManager/app.py"
#       "FLASK_ENV"  = var.environment == "production" ? "production" : "development"
#       "DATABASE"   = "/app/instance/task_manager.sqlite"
#     }
#     
#     secure_environment_variables = {
#       "SECRET_KEY" = var.secret_key
#     }
#   }
#   
#   image_registry_credential {
#     server   = azurerm_container_registry.taskmanager.login_server
#     username = azurerm_container_registry.taskmanager.admin_username
#     password = azurerm_container_registry.taskmanager.admin_password
#   }
#   
#   tags = {
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

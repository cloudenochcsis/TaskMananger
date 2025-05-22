output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.taskmanager.name
}

output "container_registry_login_server" {
  description = "Login server for the container registry"
  value       = azurerm_container_registry.taskmanager.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for the container registry"
  value       = azurerm_container_registry.taskmanager.admin_username
}

output "container_app_environment_id" {
  description = "ID of the Container App Environment"
  value       = azurerm_container_app_environment.taskmanager.id
}

output "container_app_url" {
  description = "URL of the Container App"
  value       = azurerm_container_app.taskmanager.latest_revision_fqdn
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.taskmanager.instrumentation_key
  sensitive   = true
}

output "application_insights_app_id" {
  description = "App ID for Application Insights"
  value       = azurerm_application_insights.taskmanager.app_id
}

# Uncomment if using Azure SQL Database
# output "database_server_name" {
#   description = "Name of the database server"
#   value       = azurerm_mssql_server.taskmanager.name
# }
# 
# output "database_name" {
#   description = "Name of the database"
#   value       = azurerm_mssql_database.taskmanager.name
# }
# 
# output "database_connection_string" {
#   description = "Connection string for the database"
#   value       = "Server=${azurerm_mssql_server.taskmanager.fully_qualified_domain_name};Database=${azurerm_mssql_database.taskmanager.name};User Id=${var.db_username};Password=${var.db_password}"
#   sensitive   = true
# }

# Uncomment if using Azure Container Instance instead of Container Apps
# output "container_instance_fqdn" {
#   description = "FQDN of the Container Instance"
#   value       = azurerm_container_group.taskmanager.fqdn
# }
# 
# output "container_instance_ip" {
#   description = "IP address of the Container Instance"
#   value       = azurerm_container_group.taskmanager.ip_address
# }

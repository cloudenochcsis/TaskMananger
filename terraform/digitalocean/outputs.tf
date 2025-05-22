output "app_url" {
  description = "URL of the deployed application"
  value       = digitalocean_app.taskmanager.live_url
}

output "app_id" {
  description = "ID of the App Platform application"
  value       = digitalocean_app.taskmanager.id
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = digitalocean_container_registry.taskmanager.name
}

output "container_registry_endpoint" {
  description = "Endpoint of the container registry"
  value       = digitalocean_container_registry.taskmanager.endpoint
}

output "project_id" {
  description = "ID of the DigitalOcean project"
  value       = digitalocean_project.taskmanager.id
}

# Uncomment if using managed database
# output "database_host" {
#   description = "Database host"
#   value       = digitalocean_database_cluster.postgres.host
# }
# 
# output "database_port" {
#   description = "Database port"
#   value       = digitalocean_database_cluster.postgres.port
# }
# 
# output "database_name" {
#   description = "Database name"
#   value       = digitalocean_database_db.taskmanager_db.name
# }
# 
# output "database_user" {
#   description = "Database user"
#   value       = digitalocean_database_user.taskmanager_user.name
# }
# 
# output "database_uri" {
#   description = "Database connection URI"
#   value       = digitalocean_database_cluster.postgres.uri
#   sensitive   = true
# }

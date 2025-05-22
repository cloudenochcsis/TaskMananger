# TaskManager Terraform Infrastructure as Code

This directory contains Terraform configurations for deploying the TaskManager application to various cloud providers using Infrastructure as Code (IaC) principles.

## Directory Structure

```
terraform/
├── aws/                # AWS deployment configurations
├── azure/              # Azure deployment configurations
├── digitalocean/       # DigitalOcean deployment configurations
└── modules/            # Reusable Terraform modules
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- Cloud provider CLI tools configured:
  - AWS CLI with appropriate credentials
  - Azure CLI with appropriate credentials
  - DigitalOcean CLI with API token
- Docker for building container images

## Getting Started

### 1. Choose a Cloud Provider

Navigate to the directory for your chosen cloud provider:

```bash
cd terraform/aws        # For AWS
# OR
cd terraform/azure      # For Azure
# OR
cd terraform/digitalocean  # For DigitalOcean
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Create a `terraform.tfvars` File

Create a `terraform.tfvars` file in the provider directory to set the required variables:

**For AWS:**
```hcl
project_name = "taskmanager"
environment  = "dev"
aws_region   = "us-east-1"
secret_key   = "your-secure-secret-key"
# Uncomment if using RDS
# db_username = "dbadmin"
# db_password = "YourSecurePassword123!"
```

**For Azure:**
```hcl
project_name = "taskmanager"
environment  = "dev"
location     = "eastus"
secret_key   = "your-secure-secret-key"
# Uncomment if using Azure SQL
# db_username = "dbadmin"
# db_password = "YourSecurePassword123!"
```

**For DigitalOcean:**
```hcl
project_name  = "taskmanager"
environment   = "dev"
do_token      = "your-digitalocean-api-token"
github_repo   = "yourusername/TaskMananger"
github_branch = "main"
secret_key    = "your-secure-secret-key"
```

### 4. Plan the Deployment

```bash
terraform plan -out=tfplan
```

Review the plan to ensure it will create the resources you expect.

### 5. Apply the Configuration

```bash
terraform apply tfplan
```

### 6. Build and Push the Docker Image

After the infrastructure is created, you'll need to build and push your Docker image to the created container registry.

**For AWS:**
```bash
# Get the ECR repository URL
ECR_REPO=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REPO

# Build and push the image
docker build -t $ECR_REPO:latest .
docker push $ECR_REPO:latest
```

**For Azure:**
```bash
# Get the ACR login server
ACR_SERVER=$(terraform output -raw container_registry_login_server)
ACR_USERNAME=$(terraform output -raw container_registry_admin_username)
ACR_PASSWORD=$(az acr credential show --name $(echo $ACR_SERVER | cut -d'.' -f1) --query "passwords[0].value" -o tsv)

# Login to ACR
docker login $ACR_SERVER -u $ACR_USERNAME -p $ACR_PASSWORD

# Build and push the image
docker build -t $ACR_SERVER/taskmanager:latest .
docker push $ACR_SERVER/taskmanager:latest
```

**For DigitalOcean:**
```bash
# Get the registry endpoint
REGISTRY=$(terraform output -raw container_registry_endpoint)

# Login to the registry
doctl registry login

# Build and push the image
docker build -t $REGISTRY/taskmanager:latest .
docker push $REGISTRY/taskmanager:latest
```

### 7. Access Your Application

After deployment is complete, you can access your application using the output URL:

```bash
terraform output
```

Look for the output variable containing the application URL (e.g., `alb_dns_name` for AWS, `container_app_url` for Azure, or `app_url` for DigitalOcean).

## Customizing the Deployment

### Scaling

You can adjust the scaling parameters in the `terraform.tfvars` file:

**For AWS:**
```hcl
service_min_count = 2
service_max_count = 10
```

**For Azure:**
```hcl
min_replicas = 2
max_replicas = 10
```

**For DigitalOcean:**
```hcl
instance_count = 3
```

### Database Configuration

By default, the application uses SQLite. To use a managed database service:

1. Uncomment the database-related resources in the main.tf file
2. Uncomment and set the database variables in terraform.tfvars
3. Update the application code to use the database connection string

## Cleaning Up

To destroy all created resources:

```bash
terraform destroy
```

## Security Considerations

- Store sensitive variables like `secret_key`, `db_password`, and API tokens securely
- Consider using a secrets management solution like HashiCorp Vault or cloud provider key vaults
- For production deployments, use a remote backend for storing Terraform state

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs/index.html)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [DigitalOcean Provider Documentation](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)

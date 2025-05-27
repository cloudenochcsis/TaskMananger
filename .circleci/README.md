# CircleCI Configuration for TaskManager

This directory contains CircleCI configuration for deploying the TaskManager application to AWS, Azure, and DigitalOcean.

## Required Environment Variables

### Common Variables
- `CIRCLE_SHA1`: Automatically provided by CircleCI

### AWS Deployment
- `AWS_ACCESS_KEY_ID`: AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key
- `AWS_REGION`: AWS region (e.g., us-east-1)
- `AWS_ECR_ACCOUNT_URL`: AWS ECR repository URL

### Azure Deployment
- `AZURE_SP`: Azure service principal
- `AZURE_SP_PASSWORD`: Azure service principal password
- `AZURE_SP_TENANT`: Azure tenant ID
- `AZURE_REGISTRY_NAME`: Azure Container Registry name
- `AZURE_RESOURCE_GROUP`: Resource group name
- `AKS_CLUSTER_NAME`: AKS cluster name

### DigitalOcean Deployment
- `DIGITALOCEAN_ACCESS_TOKEN`: DigitalOcean API token
- `DOCR_NAME`: DigitalOcean Container Registry name
- `DOKUBE_CLUSTER_NAME`: DigitalOcean Kubernetes cluster name

## Workflow

1. The pipeline runs tests for all commits
2. For the `main` branch, it will deploy based on the `deployment-target` parameter
3. Deployment target can be set to:
   - `aws`: Deploy to AWS ECS
   - `azure`: Deploy to Azure AKS
   - `digitalocean`: Deploy to DigitalOcean Kubernetes

## Usage

To trigger a deployment:

1. Ensure all required environment variables are set in CircleCI project settings
2. Push your changes to the `main` branch
3. The pipeline will automatically:
   - Run tests
   - Build Docker image
   - Push to the appropriate container registry
   - Deploy to the selected cloud provider

To change the deployment target, update the `deployment-target` parameter in the CircleCI UI or via API.

## Security Best Practices

- **Never hardcode secrets** (API keys, passwords, tokens) in code or config files. Always use CircleCI environment variables or contexts.
- **Use CircleCI Contexts** for managing secrets shared across multiple projects or teams.
- **Rotate secrets regularly** and update them in CircleCI project or context settings.
- **Apply the principle of least privilege**: ensure all credentials used in CI have only the permissions required for deployment.
- **Do not echo secrets** in scripts or logs. CircleCI masks environment variables, but avoid printing them directly.
- **Audit and remove unused secrets** from CircleCI settings periodically.
- **Use official, up-to-date Docker images** and pin versions to avoid unexpected changes.
- **Consider adding security scanning jobs** (e.g., Bandit for Python, Trivy for Docker images) to your pipeline for automated vulnerability checks.

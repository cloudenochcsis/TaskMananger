# Deploying TaskManager to Microsoft Azure

This guide provides step-by-step instructions for deploying the TaskManager application to Microsoft Azure using various Azure services including App Service, Container Instances, Container Apps, and Azure Database.

## Prerequisites

- Azure account with an active subscription
- Azure CLI installed and configured
- Git installed
- Docker installed (for container-based deployments)

## Deployment Options

### 1. Azure App Service with Container Registry

This approach uses Azure Container Registry to store your Docker image and Azure App Service to run the containerized application.

#### Step 1: Create Azure Container Registry

```bash
# Login to Azure
az login

# Create a resource group
az group create --name taskmanager-rg --location eastus

# Create Azure Container Registry
az acr create --resource-group taskmanager-rg --name taskmanageracr --sku Basic

# Login to the registry
az acr login --name taskmanageracr
```

#### Step 2: Build and Push Docker Image

```bash
# Build the Docker image
docker build -t taskmanager:latest .

# Tag the image for ACR
docker tag taskmanager:latest taskmanageracr.azurecr.io/taskmanager:latest

# Push the image to ACR
docker push taskmanageracr.azurecr.io/taskmanager:latest
```

#### Step 3: Create Azure App Service

```bash
# Create App Service plan
az appservice plan create --name taskmanager-plan --resource-group taskmanager-rg --is-linux --sku B1

# Create App Service
az webapp create --resource-group taskmanager-rg --plan taskmanager-plan --name taskmanager-app --deployment-container-image-name taskmanageracr.azurecr.io/taskmanager:latest

# Configure App Service to use ACR
az webapp config container set --name taskmanager-app --resource-group taskmanager-rg --docker-custom-image-name taskmanageracr.azurecr.io/taskmanager:latest --docker-registry-server-url https://taskmanageracr.azurecr.io
```

#### Step 4: Configure Environment Variables

```bash
# Set environment variables
az webapp config appsettings set --resource-group taskmanager-rg --name taskmanager-app --settings \
  FLASK_APP=TaskManager/app.py \
  FLASK_ENV=production \
  SECRET_KEY="your-secure-secret-key" \
  DATABASE="/home/site/wwwroot/instance/task_manager.sqlite"
```

### 2. Azure App Service with GitHub Actions

This approach uses GitHub Actions for CI/CD to automatically build and deploy your application to Azure App Service.

#### Step 1: Create Azure App Service

```bash
# Create App Service plan
az appservice plan create --name taskmanager-plan --resource-group taskmanager-rg --is-linux --sku B1

# Create App Service
az webapp create --resource-group taskmanager-rg --plan taskmanager-plan --name taskmanager-app --runtime "PYTHON|3.9"
```

#### Step 2: Configure GitHub Actions

Create a new file at `.github/workflows/azure-deploy.yml` with the following content:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r TaskManager/requirements.txt
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'taskmanager-app'
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
        package: .
```

#### Step 3: Add Deployment Secret to GitHub

1. In the Azure portal, go to your App Service
2. Navigate to Deployment Center > Deployment Credentials > Get publish profile
3. Copy the contents of the downloaded file
4. In your GitHub repository, go to Settings > Secrets > New repository secret
5. Create a secret named `AZURE_WEBAPP_PUBLISH_PROFILE` with the content from the publish profile

### 3. Azure Database for SQLite Alternative

Since Azure doesn't have a managed SQLite service, consider using Azure SQL Database or Azure Cosmos DB:

```bash
# Create Azure SQL Database
az sql server create --name taskmanager-sql --resource-group taskmanager-rg --location eastus --admin-user dbadmin --admin-password "YourSecurePassword123!"

az sql db create --resource-group taskmanager-rg --server taskmanager-sql --name taskmanagerdb --service-objective S0

# Allow Azure services to access the server
az sql server firewall-rule create --resource-group taskmanager-rg --server taskmanager-sql --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
```

Then update your application to use Azure SQL Database instead of SQLite.

## Monitoring and Scaling

### Application Insights

```bash
# Create Application Insights
az monitor app-insights component create --app taskmanager-insights --location eastus --resource-group taskmanager-rg

# Get the instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show --app taskmanager-insights --resource-group taskmanager-rg --query instrumentationKey -o tsv)

# Set the instrumentation key in App Service
az webapp config appsettings set --resource-group taskmanager-rg --name taskmanager-app --settings APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY
```

### Auto-Scaling

```bash
# Configure auto-scaling
az monitor autoscale create --resource-group taskmanager-rg --resource taskmanager-plan --resource-type "Microsoft.Web/serverfarms" --name taskmanager-autoscale --min-count 1 --max-count 3 --count 1

# Add a scale rule based on CPU usage
az monitor autoscale rule create --resource-group taskmanager-rg --autoscale-name taskmanager-autoscale --scale out 1 --condition "Percentage CPU > 75 avg 5m"
```

## Cleanup

When you're done with the resources, you can delete them to avoid incurring charges:

```bash
az group delete --name taskmanager-rg --yes
```

### 4. Azure Container Instances (ACI)

Azure Container Instances provides a fast and simple way to run containers without managing virtual machines or adopting a higher-level service.

#### Step 1: Create Azure Container Registry (if not already created)

```bash
# Login to Azure
az login

# Create a resource group (if not already created)
az group create --name taskmanager-rg --location eastus

# Create Azure Container Registry
az acr create --resource-group taskmanager-rg --name taskmanageracr --sku Basic

# Login to the registry
az acr login --name taskmanageracr

# Build and push the Docker image (if not already done)
docker build -t taskmanager:latest .
docker tag taskmanager:latest taskmanageracr.azurecr.io/taskmanager:latest
docker push taskmanageracr.azurecr.io/taskmanager:latest
```

#### Step 2: Enable Admin User for ACR

```bash
# Enable admin user for the container registry
az acr update --name taskmanageracr --resource-group taskmanager-rg --admin-enabled true

# Get the registry credentials
ACR_USERNAME=$(az acr credential show --name taskmanageracr --resource-group taskmanager-rg --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name taskmanageracr --resource-group taskmanager-rg --query "passwords[0].value" -o tsv)
```

#### Step 3: Create Container Instance

```bash
# Create a container instance
az container create \
  --resource-group taskmanager-rg \
  --name taskmanager-container \
  --image taskmanageracr.azurecr.io/taskmanager:latest \
  --cpu 1 \
  --memory 1.5 \
  --registry-login-server taskmanageracr.azurecr.io \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --dns-name-label taskmanager-app \
  --ports 5000 \
  --environment-variables \
    FLASK_APP=TaskManager/app.py \
    FLASK_ENV=production \
    SECRET_KEY="your-secure-secret-key" \
    DATABASE="/app/instance/task_manager.sqlite"
```

#### Step 4: Access the Application

```bash
# Get the FQDN of the container instance
FQDN=$(az container show --resource-group taskmanager-rg --name taskmanager-container --query ipAddress.fqdn -o tsv)
echo "Application is available at: http://$FQDN:5000"
```

### 5. Azure Container Apps

Azure Container Apps is a fully managed serverless container service that enables you to run microservices and containerized applications on a serverless platform.

#### Step 1: Install the Azure Container Apps extension for the CLI

```bash
# Install the Azure Container Apps extension
az extension add --name containerapp --upgrade

# Register the Microsoft.App namespace
az provider register --namespace Microsoft.App
```

#### Step 2: Create a Container Apps Environment

```bash
# Create a resource group (if not already created)
az group create --name taskmanager-rg --location eastus

# Create a Container Apps environment
az containerapp env create \
  --name taskmanager-env \
  --resource-group taskmanager-rg \
  --location eastus
```

#### Step 3: Create Azure Container Registry (if not already created)

```bash
# Create Azure Container Registry
az acr create --resource-group taskmanager-rg --name taskmanageracr --sku Basic

# Login to the registry
az acr login --name taskmanageracr

# Build and push the Docker image
docker build -t taskmanager:latest .
docker tag taskmanager:latest taskmanageracr.azurecr.io/taskmanager:latest
docker push taskmanageracr.azurecr.io/taskmanager:latest

# Enable admin user for the container registry
az acr update --name taskmanageracr --resource-group taskmanager-rg --admin-enabled true
```

#### Step 4: Create a Container App

```bash
# Get the registry credentials
ACR_USERNAME=$(az acr credential show --name taskmanageracr --resource-group taskmanager-rg --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name taskmanageracr --resource-group taskmanager-rg --query "passwords[0].value" -o tsv)

# Create a Container App
az containerapp create \
  --name taskmanager-app \
  --resource-group taskmanager-rg \
  --environment taskmanager-env \
  --image taskmanageracr.azurecr.io/taskmanager:latest \
  --registry-server taskmanageracr.azurecr.io \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --target-port 5000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 3 \
  --env-vars \
    FLASK_APP=TaskManager/app.py \
    FLASK_ENV=production \
    SECRET_KEY="your-secure-secret-key" \
    DATABASE="/app/instance/task_manager.sqlite"
```

#### Step 5: Access the Application

```bash
# Get the application URL
APP_URL=$(az containerapp show --name taskmanager-app --resource-group taskmanager-rg --query properties.configuration.ingress.fqdn -o tsv)
echo "Application is available at: https://$APP_URL"
```

#### Step 6: Configure Scaling Rules (Optional)

```bash
# Configure scaling rules based on HTTP traffic
az containerapp update \
  --name taskmanager-app \
  --resource-group taskmanager-rg \
  --scale-rule-name http-scale \
  --scale-rule-type http \
  --scale-rule-http-concurrency 50
```

## Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Azure Container Instances Documentation](https://docs.microsoft.com/en-us/azure/container-instances/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [GitHub Actions for Azure](https://github.com/Azure/actions)
- [Azure SQL Database Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/)

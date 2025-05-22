# Deploying TaskManager to DigitalOcean

This guide provides step-by-step instructions for deploying the TaskManager application to DigitalOcean using App Platform and managed databases.

## Prerequisites

- DigitalOcean account
- `doctl` CLI installed and authenticated
- Git installed
- Docker installed (optional for local testing)

## Deployment Options

### 1. DigitalOcean App Platform

App Platform is a Platform-as-a-Service (PaaS) offering that allows you to deploy applications from source code or Docker images without managing the underlying infrastructure.

#### Step 1: Install and Configure doctl

```bash
# Install doctl (macOS example)
brew install doctl

# Authenticate with your API token
doctl auth init
```

#### Step 2: Prepare the Application

Create a file named `.do/app.yaml` in your project root:

```yaml
name: taskmanager
region: nyc
services:
- name: web
  github:
    repo: yourusername/TaskMananger
    branch: main
  build_command: pip install -r TaskManager/requirements.txt
  run_command: gunicorn --workers 4 --threads 2 --bind 0.0.0.0:$PORT TaskManager.app:app
  envs:
  - key: FLASK_APP
    value: TaskManager/app.py
  - key: FLASK_ENV
    value: production
  - key: SECRET_KEY
    value: ${SECRET_KEY}
    type: SECRET
  - key: DATABASE
    value: /app/instance/task_manager.sqlite
  instance_size_slug: basic-xs
  instance_count: 1
  routes:
  - path: /
```

Make sure your `requirements.txt` includes gunicorn:

```
Flask==2.0.1
gunicorn==20.1.0
# other dependencies...
```

#### Step 3: Deploy to App Platform

```bash
# Create a new app
doctl apps create --spec .do/app.yaml

# Get the app ID
APP_ID=$(doctl apps list --format ID --no-header)

# Set the SECRET_KEY
doctl apps update $APP_ID --set-secret SECRET_KEY=your-secure-secret-key
```

### 2. DigitalOcean Container Registry and App Platform

This approach uses DigitalOcean Container Registry to store your Docker image and App Platform to run it.

#### Step 1: Create a Container Registry

```bash
# Create a container registry
doctl registry create taskmanager-registry

# Log in to the registry
doctl registry login
```

#### Step 2: Build and Push Docker Image

```bash
# Build the Docker image
docker build -t registry.digitalocean.com/taskmanager-registry/taskmanager:latest .

# Push the image to the registry
docker push registry.digitalocean.com/taskmanager-registry/taskmanager:latest
```

#### Step 3: Deploy to App Platform from Container Registry

Create a file named `.do/app-container.yaml`:

```yaml
name: taskmanager
region: nyc
services:
- name: web
  image:
    registry_type: DOCR
    repository: taskmanager-registry/taskmanager
    tag: latest
  instance_size_slug: basic-xs
  instance_count: 1
  envs:
  - key: FLASK_APP
    value: TaskManager/app.py
  - key: FLASK_ENV
    value: production
  - key: SECRET_KEY
    value: ${SECRET_KEY}
    type: SECRET
  - key: DATABASE
    value: /app/instance/task_manager.sqlite
  routes:
  - path: /
```

```bash
# Create a new app from the container
doctl apps create --spec .do/app-container.yaml

# Get the app ID
APP_ID=$(doctl apps list --format ID --no-header)

# Set the SECRET_KEY
doctl apps update $APP_ID --set-secret SECRET_KEY=your-secure-secret-key
```

### 3. DigitalOcean Managed Database (Optional)

For production, you might want to use a managed database service instead of SQLite:

#### Step 1: Create a Managed PostgreSQL Database

```bash
# Create a managed PostgreSQL database
doctl databases create taskmanager-db --engine pg --size db-s-1vcpu-1gb --region nyc1 --num-nodes 1

# Get the database connection details
DB_ID=$(doctl databases list --format ID --no-header)
DB_CONNECTION=$(doctl databases connection $DB_ID --format URI --no-header)
```

#### Step 2: Update App Configuration to Use the Database

Update your `.do/app.yaml` or `.do/app-container.yaml` file to include the database connection:

```yaml
# Add this to the envs section
envs:
- key: DATABASE_URL
  value: ${taskmanager-db.DATABASE_URL}
```

You would then need to modify your application to use PostgreSQL instead of SQLite.

## Scaling and Monitoring

### Horizontal Scaling

```bash
# Scale the app to 3 instances
doctl apps update $APP_ID --spec .do/app.yaml --set-spec-values services[0].instance_count=3
```

### Vertical Scaling

```bash
# Upgrade to a larger instance size
doctl apps update $APP_ID --spec .do/app.yaml --set-spec-values services[0].instance_size_slug=basic-s
```

### Monitoring with DigitalOcean Monitoring

DigitalOcean provides built-in monitoring for App Platform applications. You can view metrics in the DigitalOcean dashboard.

To set up alerts:

```bash
# Create an alert policy for high CPU usage
doctl monitoring alert create --compare above --value 75 --window 5m --type v1/insights/droplet/cpu
```

## CI/CD with GitHub Actions

Create a file named `.github/workflows/digitalocean.yml`:

```yaml
name: Deploy to DigitalOcean App Platform

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      
      - name: Install doctl
        uses: digitalocean/action-doctl@v2
        with:
          token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}
      
      - name: Deploy to App Platform
        run: doctl apps update ${{ secrets.APP_ID }} --spec .do/app.yaml
```

Add the following secrets to your GitHub repository:
- `DIGITALOCEAN_ACCESS_TOKEN`: Your DigitalOcean API token
- `APP_ID`: Your App Platform application ID

## Custom Domain and HTTPS

```bash
# Add a custom domain to your app
doctl apps update $APP_ID --spec .do/app.yaml --add-domain example.com
```

DigitalOcean App Platform automatically provisions and manages SSL certificates for your custom domains.

## Cleanup

When you're done with the resources, you can delete them to avoid incurring charges:

```bash
# Delete the app
doctl apps delete $APP_ID

# Delete the database
doctl databases delete $DB_ID

# Delete the container registry
doctl registry delete taskmanager-registry
```

## Additional Resources

- [DigitalOcean App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- [DigitalOcean Container Registry Documentation](https://docs.digitalocean.com/products/container-registry/)
- [DigitalOcean Managed Databases Documentation](https://docs.digitalocean.com/products/databases/)
- [doctl CLI Documentation](https://docs.digitalocean.com/reference/doctl/)

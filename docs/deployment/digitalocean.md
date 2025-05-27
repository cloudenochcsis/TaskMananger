# Deploying TaskManager to DigitalOcean

This guide provides step-by-step instructions for deploying the TaskManager application to DigitalOcean using App Platform and managed databases.

## Prerequisites

- DigitalOcean account
- `doctl` CLI installed and authenticated
- Git installed
- Docker installed (optional for local testing)

## Deployment Options

### DigitalOcean App Platform (with Container Registry)

App Platform is a Platform-as-a-Service (PaaS) offering that allows you to deploy applications from Docker images without managing the underlying infrastructure.

#### Step 1: Install and Configure doctl

```bash
# Install doctl (macOS example)
brew install doctl

# Authenticate with your API token
doctl auth init
```

#### Step 2: Create a Container Registry

```bash
# Create a container registry
doctl registry create <DOCR_NAME>

# Log in to the registry
doctl registry login
```

#### Step 3: Build and Push Docker Image

```bash
# Build the Docker image
docker build -t registry.digitalocean.com/<DOCR_NAME>/taskmanager:latest .

# Push the image to the registry
docker push registry.digitalocean.com/<DOCR_NAME>/taskmanager:latest
```

#### Step 4: Prepare the App Platform Spec

Create or update your `.do/app.yaml` file as follows:

```yaml
name: taskmanager
services:
  - name: web
    image:
      registry: registry.digitalocean.com
      repository: <DOCR_NAME>/taskmanager  # Replace <DOCR_NAME> with your actual DOCR name
      tag: latest  # Or use your preferred tag, e.g., ${CIRCLE_SHA1}
    envs:
      - key: FLASK_ENV
        value: production
      - key: SECRET_KEY
        scope: RUN_AND_BUILD_TIME
        value: ${SECRET_KEY}
    http_port: 5000
    routes:
      - path: /
    instance_count: 1
    instance_size_slug: basic-xxs
    health_check:
      http_path: /
      port: 5000
    run_command: gunicorn -b 0.0.0.0:5000 TaskManager.app:app
```

#### Step 5: Deploy to App Platform

```bash
# Create a new app
doctl apps create --spec .do/app.yaml

# Or update an existing app
doctl apps update <APP_ID> --spec .do/app.yaml
```

#### Step 6: Set Secrets (if needed)

```bash
# Set the SECRET_KEY
doctl apps update <APP_ID> --set-secret SECRET_KEY=your-secure-secret-key
```

### DigitalOcean Managed Database (Optional)

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

Update your `.do/app.yaml` file to include the database connection:

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
doctl apps update <APP_ID> --spec .do/app.yaml --set-spec-values services[0].instance_count=3
```

### Vertical Scaling

```bash
# Upgrade to a larger instance size
doctl apps update <APP_ID> --spec .do/app.yaml --set-spec-values services[0].instance_size_slug=basic-s
```

### Monitoring with DigitalOcean Monitoring

DigitalOcean provides built-in monitoring for App Platform applications. You can view metrics in the DigitalOcean dashboard.

To set up alerts:

```bash
# Create an alert policy for high CPU usage
doctl monitoring alert create --compare above --value 75 --window 5m --type v1/insights/droplet/cpu
```

## CI/CD Integration

You can automate the build, push, and deployment process using CircleCI or GitHub Actions. See the main project documentation for a CircleCI example.

## Custom Domain and HTTPS

```bash
# Add a custom domain to your app
doctl apps update <APP_ID> --spec .do/app.yaml --add-domain example.com
```

DigitalOcean App Platform automatically provisions and manages SSL certificates for your custom domains.

## Cleanup

When you're done with the resources, you can delete them to avoid incurring charges:

```bash
# Delete the app
doctl apps delete <APP_ID>

# Delete the database
doctl databases delete $DB_ID

# Delete the container registry
doctl registry delete <DOCR_NAME>
```

## Additional Resources

- [DigitalOcean App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- [DigitalOcean Container Registry Documentation](https://docs.digitalocean.com/products/container-registry/)
- [DigitalOcean Managed Databases Documentation](https://docs.digitalocean.com/products/databases/)
- [doctl CLI Documentation](https://docs.digitalocean.com/reference/doctl/)

# Deploying TaskManager to Amazon Web Services (AWS)

This guide provides step-by-step instructions for deploying the TaskManager application to AWS using various services like Elastic Beanstalk, ECS, and RDS.

## Prerequisites

- AWS account
- AWS CLI installed and configured
- Git installed
- Docker installed (for container-based deployments)

## Deployment Options

### 1. AWS Elastic Beanstalk

Elastic Beanstalk is a fully managed service that makes it easy to deploy and run applications without worrying about the infrastructure.

#### Step 1: Install the EB CLI

```bash
pip install awsebcli
```

#### Step 2: Configure the Application for Elastic Beanstalk

Create a new file named `.ebextensions/01_flask.config` in your project root:

```yaml
option_settings:
  aws:elasticbeanstalk:container:python:
    WSGIPath: TaskManager/app.py
  aws:elasticbeanstalk:application:environment:
    FLASK_APP: TaskManager/app.py
    FLASK_ENV: production
    SECRET_KEY: "your-secure-secret-key"
    DATABASE: "/var/app/current/instance/task_manager.sqlite"
```

Create a `Procfile` in your project root:

```
web: gunicorn --bind 0.0.0.0:8080 --workers 4 --threads 2 TaskManager.app:app
```

Update your `requirements.txt` file to include gunicorn:

```
Flask==2.0.1
gunicorn==20.1.0
# other dependencies...
```

#### Step 3: Initialize and Deploy with EB CLI

```bash
# Initialize EB application
eb init -p python-3.9 taskmanager

# Create an environment and deploy
eb create taskmanager-env

# For future deployments
eb deploy
```

### 2. AWS ECS (Elastic Container Service)

This approach uses Docker containers managed by ECS.

#### Step 1: Create an ECR Repository

```bash
# Create ECR repository
aws ecr create-repository --repository-name taskmanager

# Get the repository URI
REPO_URI=$(aws ecr describe-repositories --repository-names taskmanager --query 'repositories[0].repositoryUri' --output text)
```

#### Step 2: Build and Push Docker Image

```bash
# Login to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $REPO_URI

# Build and tag the image
docker build -t taskmanager:latest .
docker tag taskmanager:latest $REPO_URI:latest

# Push the image
docker push $REPO_URI:latest
```

#### Step 3: Create ECS Cluster and Task Definition

Create a file named `task-definition.json`:

```json
{
  "family": "taskmanager",
  "networkMode": "awsvpc",
  "executionRoleArn": "arn:aws:iam::<your-account-id>:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "taskmanager",
      "image": "<your-repo-uri>:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 5000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "FLASK_APP",
          "value": "TaskManager/app.py"
        },
        {
          "name": "FLASK_ENV",
          "value": "production"
        },
        {
          "name": "SECRET_KEY",
          "value": "your-secure-secret-key"
        },
        {
          "name": "DATABASE",
          "value": "/app/instance/task_manager.sqlite"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/taskmanager",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "cpu": "256",
  "memory": "512"
}
```

```bash
# Create the ECS cluster
aws ecs create-cluster --cluster-name taskmanager-cluster

# Register the task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# Create a log group
aws logs create-log-group --log-group-name /ecs/taskmanager
```

#### Step 4: Create Service with Load Balancer

```bash
# Create a VPC if you don't have one
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

# Create subnets
SUBNET1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
SUBNET2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)

# Create security group
SG_ID=$(aws ec2 create-security-group --group-name taskmanager-sg --description "TaskManager security group" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 5000 --cidr 0.0.0.0/0

# Create load balancer
LB_ARN=$(aws elbv2 create-load-balancer --name taskmanager-lb --subnets $SUBNET1 $SUBNET2 --security-groups $SG_ID --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Create target group
TG_ARN=$(aws elbv2 create-target-group --name taskmanager-tg --protocol HTTP --port 5000 --vpc-id $VPC_ID --target-type ip --query 'TargetGroups[0].TargetGroupArn' --output text)

# Create listener
aws elbv2 create-listener --load-balancer-arn $LB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_ARN

# Create ECS service
aws ecs create-service --cluster taskmanager-cluster --service-name taskmanager-service --task-definition taskmanager:1 --desired-count 2 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" --load-balancers "targetGroupArn=$TG_ARN,containerName=taskmanager,containerPort=5000"
```

### 3. AWS RDS for Database (Optional)

For production, you might want to use a managed database service instead of SQLite:

```bash
# Create a security group for RDS
DB_SG_ID=$(aws ec2 create-security-group --group-name taskmanager-db-sg --description "TaskManager DB security group" --vpc-id $VPC_ID --query 'GroupId' --output text)

# Allow connections from the application security group
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 5432 --source-group $SG_ID

# Create RDS PostgreSQL instance
aws rds create-db-instance --db-instance-identifier taskmanager-db --db-instance-class db.t3.micro --engine postgres --master-username dbadmin --master-user-password "YourSecurePassword123!" --allocated-storage 20 --vpc-security-group-ids $DB_SG_ID --db-subnet-group-name default --publicly-accessible --no-multi-az
```

You would then need to modify your application to use PostgreSQL instead of SQLite.

## CI/CD with AWS CodePipeline

### Step 1: Create a CodeCommit Repository

```bash
# Create repository
aws codecommit create-repository --repository-name taskmanager

# Add CodeCommit as a remote
git remote add codecommit https://git-codecommit.us-east-1.amazonaws.com/v1/repos/taskmanager

# Push your code
git push codecommit main
```

### Step 2: Create a CodeBuild Project

Create a `buildspec.yml` file in your project root:

```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.9
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $ECR_REPOSITORY_URI:latest .
      - docker tag $ECR_REPOSITORY_URI:latest $ECR_REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $ECR_REPOSITORY_URI:latest
      - docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
      - echo Writing image definitions file...
      - aws ecs describe-task-definition --task-definition taskmanager --query taskDefinition > taskdef.json
      - envsubst < appspec_template.yaml > appspec.yaml

artifacts:
  files:
    - appspec.yaml
    - taskdef.json
```

Create an `appspec_template.yaml` file:

```yaml
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: <TASK_DEFINITION>
        LoadBalancerInfo:
          ContainerName: "taskmanager"
          ContainerPort: 5000
```

```bash
# Create CodeBuild project
aws codebuild create-project --name taskmanager-build --source type=CODECOMMIT,location=https://git-codecommit.us-east-1.amazonaws.com/v1/repos/taskmanager --artifacts type=NO_ARTIFACTS --environment type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/amazonlinux2-x86_64-standard:3.0,privilegedMode=true --service-role codebuild-service-role
```

### Step 3: Create a CodePipeline

```bash
# Create pipeline
aws codepipeline create-pipeline --pipeline-name taskmanager-pipeline --role-arn arn:aws:iam::<your-account-id>:role/codepipeline-service-role --artifact-store type=S3,location=codepipeline-bucket

# Add source stage
aws codepipeline update-pipeline --cli-input-json file://pipeline.json
```

Create a `pipeline.json` file with your pipeline configuration.

## Monitoring and Scaling

### CloudWatch for Monitoring

```bash
# Create a dashboard
aws cloudwatch put-dashboard --dashboard-name TaskManager --dashboard-body file://dashboard.json

# Create an alarm for high CPU usage
aws cloudwatch put-metric-alarm --alarm-name TaskManager-HighCPU --alarm-description "Alarm when CPU exceeds 75%" --metric-name CPUUtilization --namespace AWS/ECS --statistic Average --period 300 --threshold 75 --comparison-operator GreaterThanThreshold --dimensions Name=ClusterName,Value=taskmanager-cluster Name=ServiceName,Value=taskmanager-service --evaluation-periods 2 --alarm-actions arn:aws:sns:us-east-1:<your-account-id>:taskmanager-alerts
```

### Auto Scaling for ECS

```bash
# Register a scalable target
aws application-autoscaling register-scalable-target --service-namespace ecs --resource-id service/taskmanager-cluster/taskmanager-service --scalable-dimension ecs:service:DesiredCount --min-capacity 1 --max-capacity 10

# Create scaling policy
aws application-autoscaling put-scaling-policy --service-namespace ecs --resource-id service/taskmanager-cluster/taskmanager-service --scalable-dimension ecs:service:DesiredCount --policy-name taskmanager-scaling --policy-type TargetTrackingScaling --target-tracking-scaling-policy-configuration file://scaling-policy.json
```

Create a `scaling-policy.json` file:

```json
{
  "TargetValue": 75.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleOutCooldown": 300,
  "ScaleInCooldown": 300
}
```

## Cleanup

When you're done with the resources, you can delete them to avoid incurring charges:

```bash
# Delete ECS service
aws ecs delete-service --cluster taskmanager-cluster --service taskmanager-service --force

# Delete ECS cluster
aws ecs delete-cluster --cluster taskmanager-cluster

# Delete ECR repository
aws ecr delete-repository --repository-name taskmanager --force

# Delete Elastic Beanstalk environment
eb terminate taskmanager-env

# Delete RDS instance
aws rds delete-db-instance --db-instance-identifier taskmanager-db --skip-final-snapshot
```

## Additional Resources

- [AWS Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/Welcome.html)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/latest/developerguide/Welcome.html)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/latest/userguide/Welcome.html)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)

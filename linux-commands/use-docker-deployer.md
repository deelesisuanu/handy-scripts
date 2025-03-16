# Docker Deployment Script

This script automates the deployment of a Docker container, optionally using Nginx as a reverse proxy with SSL support. It also supports blue-green deployments, health checks, auto-scaling, rollback on failure, interactive Docker registry login, and Slack notifications.

## Features
- Deploys a Docker container with configurable ports
- Supports Nginx reverse proxy (auto-detects if installed)
- Enables SSL via Let's Encrypt (only if Nginx is running)
- Blue-Green Deployment for zero-downtime updates
- Health checks with retry mechanism
- Auto-scaling based on CPU/memory usage
- Rollback mechanism on failure
- Supports interactive login to Docker registries (AWS ECR, GCR, DockerHub)
- Sends deployment notifications to Slack
- Supports loading environment variables from a file

## Prerequisites
- **Docker** must be installed (`docker --version` to check)
- **Nginx** (if using reverse proxy)
- **Certbot** (if enabling SSL)
- **curl** (for health checks and Slack notifications)
- **AWS CLI** (if using AWS ECR)
- **gcloud CLI** (if using Google Container Registry)

## Usage
```bash
./deploy.sh --image <docker-image> --port <port> --name <container-name> --internal-port <internal-port> [options]
```

### Required Arguments
| Argument          | Description |
|------------------|-------------|
| `--image`       | Docker image name (e.g., `nginx:latest`) |
| `--port`        | External port to expose the container |
| `--name`        | Name of the running container |
| `--internal-port` | Internal port the application listens on |

### Optional Arguments
| Argument | Default | Description |
|----------|---------|-------------|
| `--nginx` | auto | Use Nginx (`yes`/`no`) or auto-detect |
| `--nginx-config` |  | Path to Nginx config file |
| `--domain` |  | Domain name for SSL |
| `--ssl` | no | Enable SSL (`yes`/`no`) |
| `--health-check` | no | Perform health check after deployment |
| `--health-check-url` | `/health` | Custom health check endpoint |
| `--health-check-retries` | `5` | Number of health check retries |
| `--slack-url` |  | Slack Webhook for notifications |
| `--blue-green` | no | Enable blue-green deployment (`yes`/`no`) |
| `--env-vars` | no | Load environment variables (`yes`/`no`) |
| `--env-file` |  | Path to `.env` file |
| `--auto-scale` | no | Enable auto-scaling (`yes`/`no`) |
| `--scale-threshold` | `80` | CPU usage percentage for scaling |
| `--rollback-on-failure` | no | Rollback deployment if health check fails (`yes`/`no`) |
| `--docker-login` | no | Interactive login to Docker registry (`yes`/`no`) |
| `--registry-provider` | `dockerhub` | Docker registry provider (`aws`, `gcr`, `dockerhub`) |
| `--registry-url` |  | Custom Docker registry URL (if needed) |

## Example Commands

### **1. Basic Deployment**
```bash
./deploy.sh --image myapp:latest --port 8080 --name myapp --internal-port 5000
```

### **2. Deployment with Nginx Reverse Proxy**
```bash
./deploy.sh --image myapp:latest --port 8080 --name myapp --internal-port 5000 --nginx yes --nginx-config /etc/nginx/sites-enabled/myapp
```

### **3. Enable SSL (Only if Nginx is running)**
```bash
./deploy.sh --image myapp:latest --port 8080 --name myapp --internal-port 5000 --nginx yes --domain example.com --ssl yes
```

### **4. Blue-Green Deployment**
```bash
./deploy.sh --image myapp:latest --port 8080 --name myapp --internal-port 5000 --blue-green yes
```

### **5. Health Check with Custom Endpoint**
```bash
./deploy.sh --image myapp:latest --port 8080 --name myapp --internal-port 5000 --health-check yes --health-check-url /status --health-check-retries 3
```

### **6. Load Environment Variables from File**
```bash
./deploy.sh --image myapp:latest --port 8080 --name myapp --internal-port 5000 --env-vars yes --env-file .env
```

### **7. Auto-Scaling with 75% CPU Threshold**
```bash
./deploy.sh --image myapp:latest --port 8080 --name myapp --internal-port 5000 --auto-scale yes --scale-threshold 75
```

### **8. Rollback on Failure**
```bash
./deploy.sh --image myapp:latest --port 8080 --name myapp --internal-port 5000 --rollback-on-failure yes
```

### **9. Interactive Login to AWS ECR before Deployment**
```bash
./deploy.sh --image myapp:latest --port 8080 --name myapp --internal-port 5000 --docker-login yes --registry-provider aws --registry-url <aws-registry-url>
```

## Notes
- If `--ssl yes` is used, the script ensures Nginx is running before configuring SSL.
- Blue-Green deployment alternates between two container names (`app-blue` and `app-green`) to minimize downtime.
- Auto-scaling dynamically adjusts container instances based on CPU usage.
- Rollback mechanism stops and removes the new container if health checks fail.
- Slack notifications are sent if a webhook URL is provided.
- Interactive Docker login prompts the user for credentials before pulling from private registries.

## Troubleshooting
- **Docker not found?** Ensure it is installed: `sudo apt install docker.io`
- **Nginx config issues?** Check logs: `sudo systemctl status nginx`
- **SSL setup fails?** Ensure Nginx is running: `sudo systemctl start nginx`
- **Auto-scaling not working?** Check Docker stats: `docker stats`
- **Login issues?** Make sure AWS CLI or gcloud CLI is configured for registry access.

## Author
This script is maintained by Deelesi Suanu. Feel free to contribute or request features!

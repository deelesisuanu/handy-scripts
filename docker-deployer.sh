#!/bin/bash

set -e  # Exit on error

# Default values
USE_NGINX="auto"  # Auto-detect Nginx usage
NGINX_CONFIG_PATH=""
DOMAIN_NAME=""
ENABLE_SSL="no"
HEALTH_CHECK="no"
HEALTH_CHECK_RETRIES=5
HEALTH_CHECK_URL="/health"
SLACK_WEBHOOK=""
BLUE_GREEN="no"
ENABLE_ENV_VARS="no"
ENV_FILE=""
AUTO_SCALING="no"
ROLLBACK_ON_FAILURE="no"
DOCKER_REGISTRY="none"
SCALE_MIN=1
SCALE_MAX=3

# Parse Named Arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) IMAGE_NAME="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --name) CONTAINER_NAME="$2"; shift 2;;
    --internal-port) INTERNAL_PORT="$2"; shift 2;;
    --nginx) USE_NGINX="$2"; shift 2;;
    --nginx-config) NGINX_CONFIG_PATH="$2"; shift 2;;
    --domain) DOMAIN_NAME="$2"; shift 2;;
    --ssl) ENABLE_SSL="$2"; shift 2;;
    --health-check) HEALTH_CHECK="$2"; shift 2;;
    --health-check-retries) HEALTH_CHECK_RETRIES="$2"; shift 2;;
    --health-check-url) HEALTH_CHECK_URL="$2"; shift 2;;
    --slack-url) SLACK_WEBHOOK="$2"; shift 2;;
    --blue-green) BLUE_GREEN="$2"; shift 2;;
    --env-vars) ENABLE_ENV_VARS="$2"; shift 2;;
    --env-file) ENV_FILE="$2"; shift 2;;
    --auto-scaling) AUTO_SCALING="$2"; shift 2;;
    --rollback) ROLLBACK_ON_FAILURE="$2"; shift 2;;
    --registry) DOCKER_REGISTRY="$2"; shift 2;;
    --scale-min) SCALE_MIN="$2"; shift 2;;
    --scale-max) SCALE_MAX="$2"; shift 2;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

# Validate required arguments
if [ -z "$IMAGE_NAME" ] || [ -z "$PORT" ] || [ -z "$CONTAINER_NAME" ] || [ -z "$INTERNAL_PORT" ]; then
    echo "Usage: $0 --image <docker-image> --port <port> --name <container-name> --internal-port <internal-port> [options]"
    exit 1
fi

# Docker Registry Login (Interactive)
if [ "$DOCKER_REGISTRY" != "none" ]; then
    echo "Logging into Docker registry: $DOCKER_REGISTRY"
    case "$DOCKER_REGISTRY" in
        ecr)
            aws ecr get-login-password --region YOUR_AWS_REGION | docker login --username AWS --password-stdin YOUR_ECR_URL;;
        gcr)
            echo "Use 'gcloud auth configure-docker' to authenticate with GCR."
            gcloud auth configure-docker;;
        dockerhub)
            echo "Logging into Docker Hub..."
            docker login;;
        *)
            echo "Unknown registry option."
            exit 1;;
    esac
fi

# Pull the latest Docker image
echo "Pulling Docker image: $IMAGE_NAME"
docker pull "$IMAGE_NAME"

# Deploy with Blue-Green or Single Mode
if [ "$BLUE_GREEN" == "yes" ]; then
    BLUE_CONTAINER="${CONTAINER_NAME}-blue"
    GREEN_CONTAINER="${CONTAINER_NAME}-green"
    ACTIVE_CONTAINER=$(docker ps --format '{{.Names}}' | grep "${CONTAINER_NAME}-")
    NEXT_CONTAINER="$([ "$ACTIVE_CONTAINER" == "$BLUE_CONTAINER" ] && echo "$GREEN_CONTAINER" || echo "$BLUE_CONTAINER")"
    echo "Deploying $NEXT_CONTAINER..."
    docker run -d --name "$NEXT_CONTAINER" -p "$PORT:$INTERNAL_PORT" "$IMAGE_NAME"
    docker update --restart unless-stopped "$NEXT_CONTAINER"
    sleep 5
    docker stop "$ACTIVE_CONTAINER" || true
    docker rm "$ACTIVE_CONTAINER" || true
else
    echo "Deploying single container: $CONTAINER_NAME"
    RUN_CMD="docker run -d --name \"$CONTAINER_NAME\" -p \"$PORT:$INTERNAL_PORT\""
    if [ "$ENABLE_ENV_VARS" == "yes" ] && [ -f "$ENV_FILE" ]; then
        RUN_CMD+=" --env-file \"$ENV_FILE\""
    fi
    RUN_CMD+=" \"$IMAGE_NAME\""
    eval $RUN_CMD
    docker update --restart unless-stopped "$CONTAINER_NAME"
fi

# Auto Scaling Support
if [ "$AUTO_SCALING" == "yes" ]; then
    echo "Auto-scaling is enabled. Managing container instances..."
    RUNNING_CONTAINERS=$(docker ps -q --filter "name=$CONTAINER_NAME")
    RUNNING_COUNT=$(echo "$RUNNING_CONTAINERS" | wc -l)
    if [ "$RUNNING_COUNT" -lt "$SCALE_MIN" ]; then
        echo "Scaling up to minimum instances: $SCALE_MIN"
        for ((i=RUNNING_COUNT; i<SCALE_MIN; i++)); do
            docker run -d --name "$CONTAINER_NAME-$i" -p "$PORT:$INTERNAL_PORT" "$IMAGE_NAME"
        done
    elif [ "$RUNNING_COUNT" -gt "$SCALE_MAX" ]; then
        echo "Scaling down to maximum instances: $SCALE_MAX"
        EXCESS=$((RUNNING_COUNT - SCALE_MAX))
        docker ps --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | tail -n $EXCESS | xargs docker stop | xargs docker rm
    fi
fi

# Slack Notification
if [ -n "$SLACK_WEBHOOK" ]; then
    echo "Sending Slack notification..."
    curl -X POST -H 'Content-type: application/json' --data "{\"text\": \"Deployment of $IMAGE_NAME successful on port $PORT.\"}" "$SLACK_WEBHOOK"
fi

echo "Deployment complete!"

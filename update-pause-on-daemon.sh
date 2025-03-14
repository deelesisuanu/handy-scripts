#!/bin/bash

# Define required cluster and namespace
REQUIRED_CLUSTER="gke_xcel-production_europe-west1-b_xcel-test"
NAMESPACE="v2k-system"
OLD_IMAGE="gcr.io/google-containers/pause:2.0"
NEW_IMAGE="gcr.io/google-containers/pause:3.9"

# Get the current active cluster
CURRENT_CLUSTER=$(kubectl config current-context)

# Check if we are on the correct cluster
if [[ "$CURRENT_CLUSTER" != "$REQUIRED_CLUSTER" ]]; then
  echo "Error: You are on cluster '$CURRENT_CLUSTER', but this script should only run on '$REQUIRED_CLUSTER'."
  exit 1
fi

echo "Running on the correct cluster: $CURRENT_CLUSTER"

# Trim any unexpected hidden characters from OLD_IMAGE
OLD_IMAGE_CLEANED=$(echo "$OLD_IMAGE" | tr -d '[:space:]')

echo "Finding workloads using $OLD_IMAGE_CLEANED in namespace $NAMESPACE..."

# Find DaemonSets using the old image with improved JSONPath
DAEMONSETS=$(kubectl get daemonsets -n $NAMESPACE -o=jsonpath="{.items[?(@.spec.template.spec.containers[].image == \"$OLD_IMAGE_CLEANED\")].metadata.name}")

# Check if any DaemonSets need updating
if [[ -z "$DAEMONSETS" ]]; then
  echo "No DaemonSets using $OLD_IMAGE_CLEANED found in namespace $NAMESPACE."
  exit 0
fi

# Update each DaemonSet to use the new image
for DS in $DAEMONSETS; do
  echo "Updating DaemonSet: $DS..."
  kubectl set image daemonset/$DS pause=$NEW_IMAGE -n $NAMESPACE
done

# Wait for rollout of each updated DaemonSet
#for DS in $DAEMONSETS; do
#  echo "Waiting for rollout to complete for $DS..."
#  kubectl rollout status daemonset/$DS -n $NAMESPACE
#done

TIMEOUT=300  # 5 minutes
START_TIME=$(date +%s)

for DS in $DAEMONSETS; do
  echo "Waiting for rollout to complete for $DS..."

  while true; do
    kubectl rollout status daemonset/$DS -n $NAMESPACE --timeout=30s && break

    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [[ $ELAPSED -ge $TIMEOUT ]]; then
      echo "Timeout reached: DaemonSet $DS did not complete rollout in $TIMEOUT seconds."
      exit 1
    fi

    echo "Still waiting for $DS rollout..."
    sleep 10
  done
done


# Verify the update
echo "Verifying updates..."
kubectl get daemonsets -n $NAMESPACE -o=jsonpath="{range .items[*]}{.metadata.name} {.spec.template.spec.containers[*].image}{'\n'}{end}"

echo "Update completed successfully!"

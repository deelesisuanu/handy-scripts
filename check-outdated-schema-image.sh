#!/bin/bash

echo "Checking container images for Docker Schema 1 format..."

for image in $(kubectl get pods --all-namespaces -o=jsonpath="{range .items[*]}{.spec.containers[*].image}{'\n'}{end}" | sort | uniq); do
    # Extract repository path (remove tag/digest)
    clean_image=$(echo $image | cut -d':' -f1 | cut -d'@' -f1)

    echo "Checking: $clean_image"

    if gcloud container images list-tags "$clean_image" --format=json | jq -e '.[].mediaType' | grep -q "application/vnd.docker.distribution.manifest.v1+json"; then
        echo "⚠️  Schema 1 Image Found: $clean_image"
    fi
done

echo "Check complete!"

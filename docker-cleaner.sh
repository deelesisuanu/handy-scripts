#!/bin/bash

# Set the threshold percentage for disk usage
THRESHOLD=50

# Get the disk usage percentage (root partition)
USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# Get the current timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Check if usage exceeds the threshold
if [ "$USAGE" -gt "$THRESHOLD" ]; then
    echo "$TIMESTAMP - Disk usage is above $THRESHOLD% ($USAGE%), running Docker prune..."
    docker system prune -a -f
else
    echo "$TIMESTAMP - Disk usage is at $USAGE%, no action needed."
fi

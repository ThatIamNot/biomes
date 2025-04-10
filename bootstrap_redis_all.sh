#!/bin/bash

# URL from which to download the new snapshot
URL="gs://oasis-backup/world/2024/5/15/biomes-2024-05-15T15:00:38.170Z.json"

# Delete existing snapshot_backup.json file
rm -f snapshot_backup.json

# Download the new snapshot file
gsutil cp $URL snapshot_backup.json

# Define array of Redis pods
redis_pods=("redis-0" "redis-hfc-0" "redis-other-0")

# Loop through each Redis pod
for pod in "${redis_pods[@]}"; do
    echo "Port-forwarding for pod $pod"
    kubectl port-forward "pod/$pod" 6379:6379 &
    # Get the PID of the background process
    PF_PID=$!

    # Wait a little for the port-forwarding to establish
    sleep 5

    # Run the bootstrap script
    echo "Running bootstrap script for $pod"
    IS_SERVER=1 node -r ts-node/register scripts/node/bootstrap_redis_merged.ts ./snapshot_backup_ORIG.json ./snapshot_backup.json

    # Kill the port-forward process
    echo "Stopping port-forwarding for pod $pod"
    kill $PF_PID

    # Wait for port to be fully released
    sleep 5
done

echo "Bootstrap process completed for all pods."
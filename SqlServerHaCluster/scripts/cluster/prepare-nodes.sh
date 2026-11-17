#!/usr/bin/env bash
set -euo pipefail

HACLUSTER_PASSWORD="${HACLUSTER_PASSWORD:-HaCluster@2026_Zeyad}"
NODES=("sqlserver-1" "sqlserver-2" "sqlserver-3")

for node in sqlserver-1 sqlserver-2 sqlserver-3; do
    echo "Installing pacemaker-cli-utils on $node..."
    docker exec "$node" apt-get update && \
    docker exec "$node" apt-get install -y --no-install-recommends pacemaker-cli-utils
done

for node in "${NODES[@]}"; do
    echo "Checking $node..."
    docker exec "$node" id hacluster >/dev/null

    echo "Setting hacluster password non-interactively on $node..."
    echo "hacluster:${HACLUSTER_PASSWORD}" | docker exec -i "$node" chpasswd

    echo "Ensuring pcsd service is active on $node..."
    docker exec "$node" systemctl enable --now pcsd
done

echo "All nodes prepared successfully."
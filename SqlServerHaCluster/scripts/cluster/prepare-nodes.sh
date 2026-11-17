#!/usr/bin/env bash
set -euo pipefail

HACLUSTER_PASSWORD="${HACLUSTER_PASSWORD:-HaCluster@2026_Zeyad}"
NODES=("sqlserver-1" "sqlserver-2" "sqlserver-3")

for node in "${NODES[@]}"; do
    echo "Checking $node..."
    docker exec "$node" id hacluster >/dev/null

    echo "Setting hacluster password non-interactively on $node..."
    echo "hacluster:${HACLUSTER_PASSWORD}" | docker exec -i "$node" chpasswd

    echo "Ensuring pcsd service is active on $node..."
    docker exec "$node" systemctl enable --now pcsd
done

echo "All nodes prepared successfully."
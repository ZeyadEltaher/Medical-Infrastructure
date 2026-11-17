#!/usr/bin/env bash
set -euo pipefail

# Define Docker API endpoint and target containers
DOCKER_API="http://172.32.0.1:2375"
CONTAINERS=("sqlserver-1" "sqlserver-2" "sqlserver-3")

echo "=================================================="
echo " [1/7] Configuring Docker API on Host..."
echo "=================================================="
./scripts/host/configure-docker-api.sh

echo "=================================================="
echo " [2/7] Verifying Docker API..."
echo "=================================================="
./scripts/host/verify-docker-api.sh

echo "=================================================="
echo " [3/7] Starting Docker Containers (Compose Up)..."
echo "=================================================="
docker compose up -d

echo "=================================================="
echo " [3.1] Waiting for containers to be fully running via Docker API..."
echo "=================================================="

# Loop through each container to check its runtime state via Docker remote API
for container in "${CONTAINERS[@]}"; do
    echo -n "Waiting for $container to start"
    while true; do
        # Query Docker daemon API for container JSON details and extract State.Status
        status=$(curl -s "$DOCKER_API/containers/$container/json" | jq -r '.State.Status // empty' 2>/dev/null || echo "")
        
        if [[ "$status" == "running" ]]; then
            echo " -> Running! ✅"
            break
        fi
        
        echo -n "."
        sleep 2
    done
done

echo "=================================================="
echo " [3.2] Waiting for systemd inside containers to be fully ready..."
echo "=================================================="

# Wait until systemd finishes booting inside each container
for container in "${CONTAINERS[@]}"; do
    echo -n "Waiting for systemd inside $container"
    while true; do
        # Check systemd running state inside the container (running or degraded is acceptable)
        sys_state=$(docker exec "$container" systemctl is-system-running 2>/dev/null || echo "initializing")
        
        if [[ "$sys_state" == "running" ]] || [[ "$sys_state" == "degraded" ]]; then
            echo " -> Systemd Ready! 🟢 (State: $sys_state)"
            break
        fi
        
        echo -n "."
        sleep 2
    done
done

echo "=================================================="
echo " [4/7] Preparing Nodes (hacluster passwords & pcsd)..."
echo "=================================================="
./scripts/cluster/prepare-nodes.sh

echo "=================================================="
echo " [5/7] Bootstrapping Pacemaker Cluster..."
echo "=================================================="
./scripts/cluster/bootstrap-cluster.sh

echo "=================================================="
echo " [6/7] Starting Cluster Services..."
echo "=================================================="
./scripts/cluster/start-cluster.sh

echo "=================================================="
echo " [7/7] Configuring STONITH (fence_docker)..."
echo "=================================================="
./scripts/cluster/configure-stonith.sh

echo "=================================================="
echo " ✅ HA Cluster deployed and verified successfully!"
echo "=================================================="
./scripts/cluster/verify-cluster.sh
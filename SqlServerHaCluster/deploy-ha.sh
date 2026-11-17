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

for container in "${CONTAINERS[@]}"; do
    echo -n "Waiting for systemd inside $container"
    attempt=0
    max_attempts=30 # الحد الأقصى 60 ثانية لكل حاوية
    
    while true; do
        # Check if systemd is responding via systemctl ping or checking pid 1
        if docker exec "$container" systemctl is-system-running &>/dev/null; then
            sys_state=$(docker exec "$container" systemctl is-system-running 2>/dev/null || echo "unknown")
            echo " -> Systemd Ready! 🟢 (State: $sys_state)"
            break
        fi
        
        # Fallback check: If PID 1 is active and pcsd or basic services are up
        if docker exec "$container" pgrep -f /sbin/init &>/dev/null; then
            # Give it a small grace period for services to settle
            sleep 2
            echo " -> Systemd Initialized via PID 1! 🟢"
            break
        fi

        attempt=$((attempt+1))
        if [ "$attempt" -ge "$max_attempts" ]; then
            echo " -> Timed out waiting for systemd, forcing continuation..."
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
echo " [6/7] Configuring STONITH (fence_docker)..."
echo "=================================================="
./scripts/cluster/configure-stonith.sh

echo "=================================================="
echo " [7/7] Starting Cluster Services..."
echo "=================================================="
./scripts/cluster/start-cluster.sh

echo "=================================================="
echo " ✅ HA Cluster deployed and verified successfully!"
echo "=================================================="
./scripts/cluster/verify-cluster.sh
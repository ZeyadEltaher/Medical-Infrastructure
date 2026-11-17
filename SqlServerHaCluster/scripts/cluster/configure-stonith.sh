#!/usr/bin/env bash
set -euo pipefail

NODE="sqlserver-1"
HOST_MAP="sqlserver-1=http://172.32.0.1:2375,sqlserver-2=http://172.32.0.1:2375,sqlserver-3=http://172.32.0.1:2375"
HOST_LIST="sqlserver-1,sqlserver-2,sqlserver-3"

echo "Verifying fence_docker agent..."
docker exec "$NODE" pcs stonith describe fence_docker >/dev/null
docker exec "$NODE" fence_docker -o metadata >/dev/null

if ! docker exec "$NODE" pcs stonith config docker_fence >/dev/null 2>&1; then
    echo "Creating STONITH resource docker_fence..."
    docker exec "$NODE" pcs stonith create docker_fence fence_docker \
        host_map="$HOST_MAP" \
        pcmk_host_list="$HOST_LIST" \
        op monitor interval=30s
fi

echo "Updating STONITH timeouts..."
docker exec "$NODE" pcs stonith update docker_fence \
    pcmk_off_timeout=60s \
    pcmk_reboot_timeout=90s \
    pcmk_monitor_timeout=30s

echo "Enabling STONITH property..."
docker exec "$NODE" pcs property set stonith-enabled=true

docker exec "$NODE" pcs stonith config docker_fence
docker exec "$NODE" pcs property config
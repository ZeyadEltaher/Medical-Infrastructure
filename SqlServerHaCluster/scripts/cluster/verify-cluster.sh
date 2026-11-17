#!/usr/bin/env bash
set -euo pipefail

NODE="sqlserver-1"

echo "========== CLUSTER STATUS =========="
docker exec "$NODE" pcs status

echo
echo "========== CLUSTER PROPERTIES =========="
docker exec "$NODE" pcs property config

echo
echo "========== STONITH CONFIGURATION =========="
docker exec "$NODE" pcs stonith config docker_fence
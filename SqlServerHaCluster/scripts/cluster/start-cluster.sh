#!/usr/bin/env bash
set -euo pipefail

NODE="sqlserver-1"

echo "Starting cluster across all nodes..."
docker exec "$NODE" pcs cluster start --all

echo "Enabling cluster services on boot..."
docker exec "$NODE" pcs cluster enable --all

echo "Waiting 5 seconds for quorum..."
sleep 5

docker exec "$NODE" pcs status
#!/usr/bin/env bash
set -euo pipefail

API="http://172.32.0.1:2375"

response=$(curl -fsS "$API/_ping")

if [[ "$response" != "OK" ]]; then
    echo "Docker API verification failed."
    exit 1
fi

echo "Docker API is reachable."
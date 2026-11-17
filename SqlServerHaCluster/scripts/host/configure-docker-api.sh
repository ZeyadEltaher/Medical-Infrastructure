#!/usr/bin/env bash
set -euo pipefail

DOCKER_OVERRIDE_DIR="/etc/systemd/system/docker.service.d"
DOCKER_OVERRIDE_FILE="$DOCKER_OVERRIDE_DIR/override.conf"

sudo mkdir -p "$DOCKER_OVERRIDE_DIR"

sudo tee "$DOCKER_OVERRIDE_FILE" >/dev/null <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://172.32.0.1:2375
EOF

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Restarting Docker daemon..."
sudo systemctl restart docker

echo "Docker API configuration completed."
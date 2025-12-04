#!/bin/bash
set -e

# Log output to file for debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script at $(date)"

# Update system
dnf update -y

# Install Docker
dnf install -y docker git
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -L "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone repository
echo "Cloning repository..."
cd /opt
git clone ${git_repo_url} ai-observability
cd ai-observability

# Create data directories with proper ownership
echo "Setting up data directories..."
mkdir -p prometheus/data loki/data grafana/data
chown -R 65534:65534 prometheus/data  # nobody user for prometheus
chown -R 10001:10001 loki/data        # loki user
chown -R 472:472 grafana/data         # grafana user

# Start services
echo "Starting Docker Compose services..."
docker-compose up -d

# Create systemd service for auto-start on reboot
echo "Creating systemd service..."
cat > /etc/systemd/system/observability.service << 'EOF'
[Unit]
Description=AI Observability Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/ai-observability
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable observability.service

echo "User data script completed at $(date)"
echo "Grafana should be available on port 3000"
echo "OTLP HTTP should be available on port 4318"

#!/bin/bash
set -e

# Log output to file for debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script at $(date)"

# Update system
dnf update -y

# Install and start SSM agent (not pre-installed on AL2023)
echo "Installing SSM agent..."
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install Docker
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -L "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Mount persistent data volume
echo "Setting up persistent data volume..."
DATA_MOUNT="/opt/ai-observability"

# Wait for the EBS volume to be attached (Terraform attaches it after instance starts)
# Device name may be /dev/xvdf or /dev/nvme1n1 depending on instance type
echo "Waiting for data volume to be attached..."
while true; do
  if [ -b "/dev/xvdf" ]; then
    DATA_DEVICE="/dev/xvdf"
    break
  elif [ -b "/dev/nvme1n1" ]; then
    DATA_DEVICE="/dev/nvme1n1"
    break
  fi
  echo "Waiting for data volume..."
  sleep 5
done
echo "Data volume $DATA_DEVICE is attached"

# Detect if this is a raw volume or has partitions
# If it has a partition table, we need to use the first partition
if lsblk -no PTTYPE "$DATA_DEVICE" 2>/dev/null | grep -q .; then
  # Volume has partitions - use first partition (p1 for nvme, 1 for xvd)
  if [[ "$DATA_DEVICE" == *"nvme"* ]]; then
    DATA_DEVICE="$${DATA_DEVICE}p1"
  else
    DATA_DEVICE="$${DATA_DEVICE}1"
  fi
  echo "Using partition: $DATA_DEVICE"
fi

# Check if the volume/partition has a filesystem, create one if not
if ! blkid "$DATA_DEVICE" | grep -q 'TYPE='; then
  echo "Creating filesystem on $DATA_DEVICE..."
  mkfs.xfs "$DATA_DEVICE"
fi

# Create mount point and mount the volume
mkdir -p "$DATA_MOUNT"
mount "$DATA_DEVICE" "$DATA_MOUNT"

# Add to fstab for persistence across reboots (use UUID for reliability)
DATA_UUID=$(blkid -s UUID -o value "$DATA_DEVICE")
if ! grep -q "$DATA_UUID" /etc/fstab; then
  echo "UUID=$DATA_UUID $DATA_MOUNT xfs defaults,nofail 0 2" >> /etc/fstab
fi

# Handle migration from old root-volume-as-data setup
# If this was previously a root volume, data is at /opt/ai-observability/opt/ai-observability
if [ -d "$DATA_MOUNT/opt/ai-observability" ] && [ ! -f "$DATA_MOUNT/docker-compose.yml" ]; then
  echo "Detected legacy root volume layout, migrating data..."
  TEMP_MOUNT="/mnt/old-data"
  mkdir -p "$TEMP_MOUNT"
  cp -a "$DATA_MOUNT/opt/ai-observability/"* "$TEMP_MOUNT/" 2>/dev/null || true
  # Unmount, reformat, remount
  umount "$DATA_MOUNT"
  mkfs.xfs -f "$DATA_DEVICE"
  mount "$DATA_DEVICE" "$DATA_MOUNT"
  cp -a "$TEMP_MOUNT/"* "$DATA_MOUNT/"
  rm -rf "$TEMP_MOUNT"
  echo "Migration complete"
fi

# Download config files from S3
echo "Downloading config files from S3..."
cd "$DATA_MOUNT"
aws s3 sync s3://${s3_bucket}/ . --region ${aws_region}

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

# AI Observability Stack

A self-hosted observability stack for collecting and visualizing OpenTelemetry metrics and logs, optimized for AI/LLM application monitoring.

## Stack Components

| Component | Purpose | Port |
|-----------|---------|------|
| OpenTelemetry Collector | Receives OTLP data, exports to Prometheus & Loki | 4318 (HTTP) |
| Prometheus | Time-series metrics storage (730-day retention) | 9090 |
| Loki | Log aggregation and storage | 3100 |
| Grafana | Visualization and dashboards | 3000 |

## AWS Deployment

### Account & Region

| Setting | Value |
|---------|-------|
| AWS Account | `YOUR_AWS_ACCOUNT_ID` |
| Region | `eu-west-1` (Ireland) |
| VPC | `vpc-EXAMPLE_VPC_ID` |

### Endpoints

| Service | URL |
|---------|-----|
| Grafana | https://YOUR_CLOUDFRONT_GRAFANA_DOMAIN.cloudfront.net |
| OTLP HTTP | https://YOUR_CLOUDFRONT_OTLP_DOMAIN.cloudfront.net |

**OTLP Endpoints:**
```
POST https://YOUR_CLOUDFRONT_OTLP_DOMAIN.cloudfront.net/v1/metrics
POST https://YOUR_CLOUDFRONT_OTLP_DOMAIN.cloudfront.net/v1/logs
POST https://YOUR_CLOUDFRONT_OTLP_DOMAIN.cloudfront.net/v1/traces
```

**Grafana Credentials:** `admin` / `admin` (default password)

### Architecture

```
                                    ┌─────────────────────────────────────────┐
                                    │            AWS eu-west-1                │
                                    │                                         │
┌──────────────┐                    │  ┌─────────────┐    ┌───────────────┐   │
│ OTLP Client  │──HTTPS:443───────────▶│ CloudFront  │───▶│ EC2 t3.small  │   │
└──────────────┘                    │  │ (OTLP)      │    │               │   │
                                    │  └─────────────┘    │ ┌───────────┐ │   │
┌──────────────┐                    │                     │ │  OTel     │ │   │
│   Browser    │──HTTPS:443──────────▶ ┌─────────────┐    │ │ Collector │ │   │
└──────────────┘                    │  │ CloudFront  │───▶│ └─────┬─────┘ │   │
                                    │  │ (Grafana)   │    │       │       │   │
                                    │  └─────────────┘    │   ┌───┴───┐   │   │
                                    │                     │   ▼       ▼   │   │
                                    │                     │ ┌────┐ ┌────┐ │   │
                                    │                     │ │Prom│ │Loki│ │   │
                                    │                     │ └──┬─┘ └─┬──┘ │   │
                                    │                     │    │     │    │   │
                                    │                     │    └──┬──┘    │   │
                                    │                     │       ▼       │   │
                                    │                     │  ┌────────┐   │   │
                                    │                     │  │Grafana │   │   │
                                    │  ┌─────────────┐    │  └────────┘   │   │
                                    │  │ EBS 50GB    │◀───│               │   │
                                    │  │ (gp3)       │    └───────────────┘   │
                                    │  └─────────────┘                        │
                                    │         │                               │
                                    │         ▼                               │
                                    │  ┌─────────────┐                        │
                                    │  │ DLM Daily   │                        │
                                    │  │ Snapshots   │                        │
                                    │  │ (30 days)   │                        │
                                    │  └─────────────┘                        │
                                    └─────────────────────────────────────────┘
```

### Infrastructure Details

| Resource | Configuration |
|----------|---------------|
| EC2 Instance | `t3.small` (2 vCPU, 2GB RAM) |
| EBS Volume | 50GB gp3, persists on termination |
| CloudFront | 2 distributions (Grafana + OTLP), HTTPS termination |
| Backups | Daily EBS snapshots via DLM, 30-day retention |
| Monitoring | CloudWatch alarm at 65% CPU, email alerts |
| Config Storage | S3 bucket with all config files |

### Scaling Options

This deployment supports **vertical scaling** (scale-up):

1. **Resize the instance:**
   ```bash
   # Update terraform/terraform.tfvars
   instance_type = "t3.medium"  # or t3.large, t3.xlarge

   # Apply changes (will stop/start instance)
   cd terraform
   terraform apply
   ```

2. **Increase EBS volume:**
   ```bash
   # Update terraform/terraform.tfvars
   ebs_volume_size = 100  # GB

   # Apply and extend filesystem on EC2
   terraform apply
   ```

| Instance Type | vCPU | RAM | Monthly Cost* |
|---------------|------|-----|---------------|
| t3.small | 2 | 2GB | ~$15 |
| t3.medium | 2 | 4GB | ~$30 |
| t3.large | 2 | 8GB | ~$60 |

*Excludes EBS, CloudFront, and data transfer costs

### Backups & Recovery

**Automated backups:**
- Daily EBS snapshots at 3:00 AM UTC
- Incremental (only changed blocks)
- 30-day retention

**To restore from a snapshot:**
```bash
# List available snapshots
aws ec2 describe-snapshots --owner-ids self \
  --filters "Name=tag:Name,Values=*ai-observability*" \
  --query 'Snapshots[*].[SnapshotId,StartTime,VolumeSize]' \
  --region eu-west-1

# Create volume from snapshot
aws ec2 create-volume \
  --snapshot-id snap-xxxxxxxxx \
  --availability-zone eu-west-1a \
  --volume-type gp3 \
  --region eu-west-1
```

### Accessing the EC2 Instance

**Via SSM (no SSH key needed):**
```bash
aws ssm start-session --target i-EXAMPLE_INSTANCE_ID --region eu-west-1
```

**Via SSH:**
```bash
ssh -i ~/.ssh/id_ed25519 ec2-user@YOUR_EC2_PUBLIC_IP
```

### Updating Configuration

Config files are stored in S3 and synced to EC2 on startup:

```bash
# 1. Modify local config files
# 2. Apply terraform to upload to S3
cd terraform
terraform apply

# 3. Sync and restart on EC2
aws ssm send-command \
  --instance-ids i-EXAMPLE_INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["aws s3 sync s3://ai-observability-configs-YOUR_AWS_ACCOUNT_ID/ /opt/ai-observability/ --region eu-west-1 && cd /opt/ai-observability && docker-compose restart"]' \
  --region eu-west-1
```

---

## Local Development

### Prerequisites

- Docker & Docker Compose

### Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd ai-observability

# Create data directories
mkdir -p prometheus/data loki/data grafana/data

# Set permissions
sudo chown -R 65534:65534 prometheus/data  # prometheus user
sudo chown -R 10001:10001 loki/data         # loki user
sudo chown -R 472:472 grafana/data          # grafana user

# Start the stack
docker-compose up -d
```

### Local Endpoints

| Service | URL |
|---------|-----|
| Grafana | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| Loki | http://localhost:3100 |
| OTLP HTTP | http://localhost:4318 |

### Sending Test Data

**Metrics:**
```bash
curl -X POST http://localhost:4318/v1/metrics \
  -H "Content-Type: application/json" \
  -d '{"resourceMetrics":[]}'
```

**Logs:**
```bash
curl -X POST http://localhost:4318/v1/logs \
  -H "Content-Type: application/json" \
  -d '{"resourceLogs":[]}'
```

### Stopping the Stack

```bash
docker-compose down
```

To also remove data volumes:
```bash
docker-compose down -v
rm -rf prometheus/data loki/data grafana/data
```

---

## Terraform Management

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials

### Initialize

```bash
cd terraform
terraform init
```

### Plan & Apply

```bash
terraform plan
terraform apply
```

### Destroy

```bash
terraform destroy
```

**Note:** EBS volume is configured with `delete_on_termination = false` to protect data. Manually delete if needed.

---

## Cost Estimate

| Resource | Monthly Cost |
|----------|--------------|
| EC2 t3.small | ~$15 |
| EBS 50GB gp3 | ~$4 |
| CloudFront (light usage) | ~$1-5 |
| EBS Snapshots | ~$1-2 |
| **Total** | **~$21-26** |

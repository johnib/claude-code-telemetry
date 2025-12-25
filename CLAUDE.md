# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Self-hosted OpenTelemetry observability stack for AI/LLM application monitoring (specifically Claude Code telemetry). Collects metrics and logs via OTLP, stores in Prometheus/Loki, and visualizes in Grafana.

## Local Development

The same `docker-compose.yml` used in production can be run locally for testing.

### Quick Start
```bash
docker-compose up -d
```

### Access URLs (Local)

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | - |
| Loki | http://localhost:3100 | - |
| OTLP HTTP | http://localhost:4318 | - |

### Verify Stack Health
```bash
# Check container status
docker-compose ps

# View OTel Collector logs
docker-compose logs -f otel-collector

# Check service readiness
curl http://localhost:3100/ready   # Loki
curl http://localhost:9090/-/ready # Prometheus
```

### Reset Data (DESTRUCTIVE - USER CONSENT REQUIRED)

This will delete all collected metrics, logs, and Grafana configuration. Only run if you explicitly intend to wipe all data:

```bash
docker-compose down -v
rm -rf loki/data prometheus/data grafana/data
docker-compose up -d
```

### Local vs Production

| Aspect | Local | Production |
|--------|-------|------------|
| OTLP endpoint | http://localhost:4318 | https://YOUR_CLOUDFRONT_OTLP_DOMAIN.cloudfront.net |
| Grafana | http://localhost:3000 | Via CloudFront |
| Authentication | None | None (CloudFront public) |
| Data persistence | Local `./*/data` dirs | EC2 EBS volumes |

## Common Commands

### Docker Compose
```bash
# Start the stack
docker-compose up -d

# Stop the stack
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Restart a specific service
docker-compose restart otel-collector
```

### Terraform (AWS Infrastructure)
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Update EC2 Configuration
After modifying config files, sync to S3 and restart services:
```bash
cd terraform && terraform apply
aws ssm send-command \
  --instance-ids i-EXAMPLE_INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["aws s3 sync s3://claude-code-telemetry-configs-YOUR_AWS_ACCOUNT_ID/ /opt/claude-code-telemetry/ --region eu-west-1 --exact-timestamps && cd /opt/claude-code-telemetry && docker-compose pull && docker-compose up -d"]' \
  --region eu-west-1
```

### Access EC2 Instance
```bash
aws ssm start-session --target i-EXAMPLE_INSTANCE_ID --region eu-west-1
```

## Architecture

```
OTLP Client → CloudFront (HTTPS) → EC2 → OTel Collector → Prometheus (metrics)
                                                        → Loki (logs)
                                                        → Grafana (visualization)
```

**Data Flow:**
1. OTLP HTTP receiver (port 4318) accepts metrics/logs
2. OTel Collector processes and routes data:
   - Metrics → Prometheus exporter (scraped by Prometheus)
   - Logs → Loki via OTLP HTTP
3. Grafana queries both for dashboards

## Key Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Container orchestration (4 services) |
| `otel-collector/config.yaml` | OTLP receivers, processors, exporters |
| `prometheus/prometheus.yml` | Scrape configs (targets otel-collector:8889) |
| `loki/loki-config.yml` | Log storage, retention (730d), OTLP labels |
| `grafana/provisioning/` | Datasources and dashboards auto-provisioning |

## Terraform Resources

- **EC2**: t3.small with 50GB gp3 EBS
- **CloudFront**: 2 distributions (Grafana + OTLP endpoints) with 60s origin timeout
- **S3**:
  - `claude-code-telemetry-configs-*`: Config storage, synced to EC2 on startup
  - `claude-code-telemetry-cloudfront-logs-*`: CloudFront access logs (7-day retention)
- **DLM**: Daily EBS snapshots with 30-day retention
- **CloudWatch Alarms**:
  - CPU > 65%
  - Disk > 65% (requires CloudWatch agent)
  - CloudFront Grafana 5xx > 1%
  - CloudFront OTLP 5xx > 1%

## Port Reference

| Port | Service | Access |
|------|---------|--------|
| 4318 | OTLP HTTP | CloudFront → EC2 |
| 3000 | Grafana | CloudFront → EC2 |
| 8889 | OTel Prometheus exporter | Internal (scraped by Prometheus) |
| 9090 | Prometheus | Internal |
| 3100 | Loki | Internal |

## OTel Collector Reliability Features

- **Memory Limiter**: 400MB limit with 100MB spike buffer - prevents OOM crashes
- **Retry on Failure**: Loki exporter retries failed requests (1s initial, 30s max, 5min timeout)
- **Sending Queue**: 5000 item queue buffers logs during Loki unavailability

## Log Label Indexing

The OTel Collector promotes these attributes to Loki labels for querying:
`service_name`, `user_email`, `event_name`, `tool_name`, `model`, `success`, `decision`

Note: Raw OTLP uses dot notation (`user.email`, `event.name`) which is transformed to underscore notation for Loki labels.

## Pinned Image Versions

All Docker images are pinned to avoid unexpected breaking changes:
- `otel/opentelemetry-collector-contrib:0.140.0`
- `grafana/loki:3.6.2`
- `prom/prometheus:v3.7.3`
- `grafana/grafana:12.3.0`

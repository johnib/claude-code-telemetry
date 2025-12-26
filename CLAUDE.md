# CLAUDE.md

This file provides context for AI assistants (like Claude Code) working on this repository.

## Project Overview

Self-hosted OpenTelemetry observability stack for Claude Code telemetry. Collects metrics and logs via OTLP, stores in Prometheus/Loki, and visualizes in Grafana.

**For user documentation, see [README.md](README.md).**

## Quick Reference

```bash
# Start locally
docker-compose up -d

# Access Grafana
open http://localhost:3000  # admin/admin

# View collector logs
docker-compose logs -f otel-collector

# Deploy to AWS
cd terraform && terraform init && terraform apply
```

## Architecture

```
Claude Code  ──OTLP:4318──▶  OTel Collector  ──▶  Prometheus (metrics)
                                             ──▶  Loki (logs)
                                             ──▶  Grafana (dashboards)
```

## Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Container orchestration (4 services) |
| `otel-collector/config.yaml` | OTLP receivers, processors, exporters |
| `prometheus/prometheus.yml` | Scrape config (targets otel-collector:8889) |
| `loki/loki-config.yml` | Log storage, retention (730d), OTLP labels |
| `grafana/provisioning/` | Datasources and dashboards auto-provisioning |
| `terraform/` | AWS infrastructure (EC2, CloudFront, S3, DLM) |

## Data Flow

1. Claude Code sends OTLP to port 4318 (HTTP)
2. OTel Collector processes and routes:
   - Metrics → Prometheus exporter (scraped on :8889)
   - Logs → Loki via OTLP HTTP
3. Grafana queries both backends

## OTel Collector Details

**Processors:**
- `memory_limiter`: 400MB limit, 100MB spike buffer
- `transform/logs`: Promotes attributes to Loki labels
- `transform/metrics`: Promotes attributes to Prometheus labels

**Indexed Loki Labels:**
`service_name`, `user_email`, `event_name`, `tool_name`, `model`, `success`, `decision`

Note: Raw OTLP uses dot notation (`user.email`) → transformed to underscore (`user_email`).

## Terraform Resources

- **EC2**: t3.small, 20GB root + 50GB data volume
- **CloudFront**: 2 distributions (Grafana :3000, OTLP :4318)
- **S3**: Config bucket + CloudFront logs bucket
- **DLM**: Daily snapshots, 30-day retention
- **CloudWatch**: CPU, disk, and 5xx error alarms

## Common Tasks

### Reset Local Data (Destructive)
```bash
docker-compose down -v
rm -rf loki/data prometheus/data grafana/data
docker-compose up -d
```

### Update AWS Deployment
```bash
cd terraform && terraform apply
# Then SSH/SSM to EC2 and run:
cd /opt/claude-code-telemetry && docker-compose pull && docker-compose up -d
```

## Pinned Versions

- `otel/opentelemetry-collector-contrib:0.140.0`
- `grafana/loki:3.6.2`
- `prom/prometheus:v3.7.3`
- `grafana/grafana:12.3.0`

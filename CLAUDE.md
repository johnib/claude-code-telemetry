# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Self-hosted OpenTelemetry observability stack for AI/LLM application monitoring (specifically Claude Code telemetry). Collects metrics and logs via OTLP, stores in Prometheus/Loki, and visualizes in Grafana.

## Common Commands

### Local Development
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
  --parameters 'commands=["aws s3 sync s3://ai-observability-configs-YOUR_AWS_ACCOUNT_ID/ /opt/ai-observability/ --region eu-west-1 && cd /opt/ai-observability && docker-compose restart"]' \
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
- **CloudFront**: 2 distributions (Grafana + OTLP endpoints)
- **S3**: Config storage, synced to EC2 on startup
- **DLM**: Daily EBS snapshots with 30-day retention
- **CloudWatch**: CPU alarm at 65%

## Port Reference

| Port | Service | Access |
|------|---------|--------|
| 4318 | OTLP HTTP | CloudFront → EC2 |
| 3000 | Grafana | CloudFront → EC2 |
| 8889 | OTel Prometheus exporter | Internal (scraped by Prometheus) |
| 9090 | Prometheus | Internal |
| 3100 | Loki | Internal |

## Log Label Indexing

The OTel Collector promotes these attributes to Loki labels for querying:
`service_name`, `organization_id`, `user_email`, `user_id`, `session_id`, `event_name`, `tool_name`, `model`, `success`, `decision`

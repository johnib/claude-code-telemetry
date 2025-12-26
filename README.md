# Claude Code Telemetry

Track your AI coding costs, token usage, and productivity metrics with a self-hosted observability stack.

**What you get:**
- Real-time cost tracking per user, session, and model
- Token usage analytics (input, output, cache hits)
- Tool usage patterns and success rates
- Session activity and productivity insights
- 2-year data retention with automated backups

## Quick Start

### 1. Deploy the Stack

**Option A: Local (Docker)**
```bash
git clone https://github.com/johnib/claude-code-telemetry.git
cd claude-code-telemetry
docker-compose up -d
```

**Option B: AWS (Terraform)**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
terraform init && terraform apply
```

### 2. Configure Claude Code

Add to your Claude Code settings file (`~/.claude/settings.json`):

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4318",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "http/protobuf"
  }
}
```

For AWS deployment, use your CloudFront OTLP endpoint:
```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "https://YOUR_CLOUDFRONT_DOMAIN.cloudfront.net",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "http/protobuf"
  }
}
```

**Optional settings:**
```json
{
  "env": {
    "OTEL_METRIC_EXPORT_INTERVAL": "10000",
    "OTEL_LOGS_EXPORT_INTERVAL": "5000"
  }
}
```

### 3. View Your Dashboards

Open Grafana at `http://localhost:3000` (or your CloudFront URL).

**Default credentials:** `admin` / `admin`

Two dashboards are pre-configured:

| Dashboard | What it shows |
|-----------|---------------|
| **Claude Code Usage** | Cost ($), tokens, sessions, lines of code, active time |
| **Claude Code Logs** | Tool executions, API requests, user prompts, errors |

---

## What Gets Tracked

### Metrics
- **Cost**: USD spent per model, user, and session
- **Tokens**: Input, output, cache read, cache creation
- **Sessions**: Count and duration
- **Lines of code**: Written via Claude Code
- **Active time**: Time spent coding

### Logs (Events)
- `api_request` - Each Claude API call with model, tokens, cost, duration
- `tool_decision` - Accept/reject decisions for tool permissions
- `tool_result` - Tool execution results with success/failure status
- `user_prompt` - User prompts (optional, requires `OTEL_LOG_USER_PROMPTS=1`)

### Filterable Dimensions
All data can be filtered by:
- User email
- Session ID
- Model (claude-opus-4, claude-sonnet-4, etc.)
- Tool name
- Success/failure status

---

## Architecture

```
Claude Code  ──OTLP──▶  OTel Collector  ──▶  Prometheus (metrics)
                                        ──▶  Loki (logs)
                                        ──▶  Grafana (dashboards)
```

| Component | Purpose | Port |
|-----------|---------|------|
| OpenTelemetry Collector | Receives OTLP, routes to storage | 4318 |
| Prometheus | Time-series metrics (730-day retention) | 9090 |
| Loki | Log aggregation (730-day retention) | 3100 |
| Grafana | Visualization | 3000 |

---

## Deployment Options

### Local Development

Best for: Testing, single-user, or home lab setups.

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f
```

**Endpoints:**
- Grafana: http://localhost:3000
- OTLP: http://localhost:4318

### AWS Production

Best for: Teams, always-on monitoring, secure HTTPS endpoints.

```
                                    ┌─────────────────────────────────────────┐
                                    │              AWS Region                 │
                                    │                                         │
┌──────────────┐                    │  ┌─────────────┐    ┌───────────────┐   │
│ Claude Code  │──HTTPS:443───────────▶│ CloudFront  │───▶│ EC2 t3.small  │   │
└──────────────┘                    │  │ (OTLP)      │    │               │   │
                                    │  └─────────────┘    │ ┌───────────┐ │   │
┌──────────────┐                    │                     │ │   OTel    │ │   │
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

**What Terraform creates:**
- EC2 t3.small (~$15/mo) with Docker
- CloudFront HTTPS endpoints for Grafana and OTLP
- 50GB encrypted EBS with daily snapshots
- CloudWatch alerts for CPU and disk usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region      = "eu-west-1"
project_name    = "claude-code-telemetry"
instance_type   = "t3.small"
ebs_volume_size = 50
alert_email     = "your-email@example.com"
```

Deploy:
```bash
terraform init
terraform apply
```

Terraform outputs your endpoints:
```
grafana_url = "https://d1234567890.cloudfront.net"
otlp_http_endpoint = "https://d0987654321.cloudfront.net"
```

---

## Cost Estimate (AWS)

| Resource | Monthly |
|----------|---------|
| EC2 t3.small | ~$15 |
| EBS 50GB gp3 | ~$4 |
| CloudFront | ~$1-5 |
| Snapshots | ~$1-2 |
| **Total** | **~$21-26** |

Scale up by changing `instance_type` to `t3.medium` (~$30/mo) or `t3.large` (~$60/mo).

---

## Security Considerations

This stack is designed for **internal/trusted use**:

- CloudFront endpoints are public (no auth by default)
- Grafana uses default admin credentials
- OTLP endpoint accepts data from anyone who knows the URL

**For production teams**, consider:
1. Change Grafana admin password immediately
2. Add CloudFront WAF rules or IP allowlists
3. Use VPN or private endpoints for sensitive deployments
4. Review what telemetry data you're comfortable storing

---

## Telemetry Schema

See [docs/claude-code-telemetry-schema.md](docs/claude-code-telemetry-schema.md) for the complete OTLP schema reference.

---

## Maintenance

### Update Configuration

```bash
# Edit config files locally, then:
cd terraform && terraform apply

# Restart services on EC2:
aws ssm start-session --target INSTANCE_ID --region eu-west-1
# Then run: cd /opt/claude-code-telemetry && docker-compose pull && docker-compose up -d
```

### Backups

- **Automatic**: Daily EBS snapshots, 30-day retention
- **Manual**: Access via AWS Console or `aws ec2 describe-snapshots`

### Scaling

```bash
# In terraform.tfvars:
instance_type = "t3.medium"  # More RAM for larger workloads
ebs_volume_size = 100        # More storage

terraform apply
```

---

## Troubleshooting

**No data appearing?**
1. Check Claude Code settings are correct
2. Verify OTLP endpoint is reachable: `curl -X POST http://localhost:4318/v1/metrics`
3. Check OTel Collector logs: `docker-compose logs otel-collector`

**High memory usage?**
- OTel Collector has a 400MB memory limit with automatic backpressure
- Consider scaling to t3.medium if you have many concurrent users

**Dashboard not loading?**
- Grafana may take 30-60 seconds to start on first boot
- Check: `docker-compose logs grafana`

---

## License

MIT

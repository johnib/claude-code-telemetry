# S3 bucket for config files
resource "aws_s3_bucket" "configs" {
  bucket = "${var.project_name}-configs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-configs"
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Block public access
resource "aws_s3_bucket_public_access_block" "configs" {
  bucket = aws_s3_bucket.configs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload docker-compose.yml
resource "aws_s3_object" "docker_compose" {
  bucket = aws_s3_bucket.configs.id
  key    = "docker-compose.yml"
  source = "${path.module}/../docker-compose.yml"
  etag   = filemd5("${path.module}/../docker-compose.yml")
}

# Upload otel-collector config
resource "aws_s3_object" "otel_config" {
  bucket = aws_s3_bucket.configs.id
  key    = "otel-collector/config.yaml"
  source = "${path.module}/../otel-collector/config.yaml"
  etag   = filemd5("${path.module}/../otel-collector/config.yaml")
}

# Upload prometheus config
resource "aws_s3_object" "prometheus_config" {
  bucket = aws_s3_bucket.configs.id
  key    = "prometheus/prometheus.yml"
  source = "${path.module}/../prometheus/prometheus.yml"
  etag   = filemd5("${path.module}/../prometheus/prometheus.yml")
}

# Upload loki config
resource "aws_s3_object" "loki_config" {
  bucket = aws_s3_bucket.configs.id
  key    = "loki/loki-config.yml"
  source = "${path.module}/../loki/loki-config.yml"
  etag   = filemd5("${path.module}/../loki/loki-config.yml")
}

# Upload grafana datasources
resource "aws_s3_object" "grafana_datasources" {
  bucket = aws_s3_bucket.configs.id
  key    = "grafana/provisioning/datasources/prometheus.yml"
  source = "${path.module}/../grafana/provisioning/datasources/prometheus.yml"
  etag   = filemd5("${path.module}/../grafana/provisioning/datasources/prometheus.yml")
}

# Upload grafana dashboard config
resource "aws_s3_object" "grafana_dashboards_config" {
  bucket = aws_s3_bucket.configs.id
  key    = "grafana/provisioning/dashboards/dashboards.yml"
  source = "${path.module}/../grafana/provisioning/dashboards/dashboards.yml"
  etag   = filemd5("${path.module}/../grafana/provisioning/dashboards/dashboards.yml")
}

# Upload grafana dashboard - claude-code metrics
resource "aws_s3_object" "grafana_dashboard_metrics" {
  bucket = aws_s3_bucket.configs.id
  key    = "grafana/provisioning/dashboards/claude-code.json"
  source = "${path.module}/../grafana/provisioning/dashboards/claude-code.json"
  etag   = filemd5("${path.module}/../grafana/provisioning/dashboards/claude-code.json")
}

# Upload grafana dashboard - claude-code logs
resource "aws_s3_object" "grafana_dashboard_logs" {
  bucket = aws_s3_bucket.configs.id
  key    = "grafana/provisioning/dashboards/claude-code-logs.json"
  source = "${path.module}/../grafana/provisioning/dashboards/claude-code-logs.json"
  etag   = filemd5("${path.module}/../grafana/provisioning/dashboards/claude-code-logs.json")
}

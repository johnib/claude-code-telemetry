# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

# Email subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm - CPU > 65%
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 65
  alarm_description   = "CPU utilization exceeds 65% - consider scaling up the instance"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.observability.id
  }

  tags = {
    Name = "${var.project_name}-high-cpu-alarm"
  }
}

# CloudWatch Alarm - Memory (optional, requires CloudWatch agent)
# Uncomment if you install CloudWatch agent on the instance
# resource "aws_cloudwatch_metric_alarm" "high_memory" {
#   alarm_name          = "${var.project_name}-high-memory"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "mem_used_percent"
#   namespace           = "CWAgent"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 80
#   alarm_description   = "Memory utilization exceeds 80%"
#   alarm_actions       = [aws_sns_topic.alerts.arn]
#   ok_actions          = [aws_sns_topic.alerts.arn]
#
#   dimensions = {
#     InstanceId = aws_instance.observability.id
#   }
# }

# CloudWatch Alarm - Disk Space (requires CloudWatch agent)
resource "aws_cloudwatch_metric_alarm" "low_disk" {
  alarm_name          = "${var.project_name}-low-disk"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 65
  alarm_description   = "Disk usage exceeds 65% - check Prometheus/Loki data retention"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.observability.id
    path       = "/"
    device     = "nvme0n1p1"
    fstype     = "xfs"
  }

  tags = {
    Name = "${var.project_name}-low-disk-alarm"
  }
}

# CloudWatch Alarm - CloudFront 5xx errors (Grafana)
resource "aws_cloudwatch_metric_alarm" "cloudfront_grafana_5xx" {
  alarm_name          = "${var.project_name}-cloudfront-grafana-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "CloudFront Grafana distribution 5xx error rate exceeds 1%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DistributionId = aws_cloudfront_distribution.grafana.id
    Region         = "Global"
  }

  tags = {
    Name = "${var.project_name}-cloudfront-grafana-5xx-alarm"
  }
}

# CloudWatch Alarm - CloudFront 5xx errors (OTLP)
resource "aws_cloudwatch_metric_alarm" "cloudfront_otlp_5xx" {
  alarm_name          = "${var.project_name}-cloudfront-otlp-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "CloudFront OTLP distribution 5xx error rate exceeds 1% - developers may be losing telemetry"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DistributionId = aws_cloudfront_distribution.otlp.id
    Region         = "Global"
  }

  tags = {
    Name = "${var.project_name}-cloudfront-otlp-5xx-alarm"
  }
}

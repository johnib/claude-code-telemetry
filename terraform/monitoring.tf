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

# CloudWatch Alarm - Disk Space (optional, requires CloudWatch agent)
# resource "aws_cloudwatch_metric_alarm" "low_disk" {
#   alarm_name          = "${var.project_name}-low-disk"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "disk_used_percent"
#   namespace           = "CWAgent"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 80
#   alarm_description   = "Disk usage exceeds 80%"
#   alarm_actions       = [aws_sns_topic.alerts.arn]
#
#   dimensions = {
#     InstanceId = aws_instance.observability.id
#     path       = "/"
#     device     = "xvda1"
#     fstype     = "xfs"
#   }
# }

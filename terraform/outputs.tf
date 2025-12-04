output "grafana_url" {
  description = "Grafana URL (HTTPS via CloudFront)"
  value       = "https://${aws_cloudfront_distribution.grafana.domain_name}"
}

output "otlp_http_endpoint" {
  description = "OTLP HTTP endpoint (HTTPS via CloudFront)"
  value       = "https://${aws_cloudfront_distribution.otlp.domain_name}"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.observability.id
}

output "instance_public_ip" {
  description = "Elastic IP address"
  value       = aws_eip.observability.public_ip
}

output "instance_public_dns" {
  description = "EC2 public DNS name"
  value       = aws_eip.observability.public_dns
}

output "ssh_command" {
  description = "SSH command to connect (if key pair configured)"
  value       = var.key_pair_name != null ? "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_eip.observability.public_ip}" : "Use SSM Session Manager: aws ssm start-session --target ${aws_instance.observability.id}"
}

output "ssm_connect_command" {
  description = "SSM Session Manager command"
  value       = "aws ssm start-session --target ${aws_instance.observability.id} --region ${var.aws_region}"
}

output "grafana_cloudfront_distribution_id" {
  description = "CloudFront distribution ID for Grafana"
  value       = aws_cloudfront_distribution.grafana.id
}

output "otlp_cloudfront_distribution_id" {
  description = "CloudFront distribution ID for OTLP"
  value       = aws_cloudfront_distribution.otlp.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

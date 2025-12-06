# CloudFront Distribution for Grafana
resource "aws_cloudfront_distribution" "grafana" {
  enabled         = true
  comment         = "${var.project_name} - Grafana"
  price_class     = "PriceClass_100" # US, Canada, Europe only (cheapest)
  http_version    = "http2and3"
  is_ipv6_enabled = true

  origin {
    domain_name = aws_eip.observability.public_dns
    origin_id   = "grafana-origin"

    custom_origin_config {
      http_port              = 3000
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 60
    }
  }

  logging_config {
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "grafana/"
    include_cookies = false
  }

  default_cache_behavior {
    target_origin_id       = "grafana-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin", "Authorization"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    compress    = true
  }

  # WebSocket support for live dashboards
  ordered_cache_behavior {
    path_pattern           = "/api/live/*"
    target_origin_id       = "grafana-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-grafana-cf"
  }
}

# CloudFront Distribution for OTLP HTTP
resource "aws_cloudfront_distribution" "otlp" {
  enabled         = true
  comment         = "${var.project_name} - OTLP HTTP"
  price_class     = "PriceClass_100" # US, Canada, Europe only (cheapest)
  http_version    = "http2and3"
  is_ipv6_enabled = true

  origin {
    domain_name = aws_eip.observability.public_dns
    origin_id   = "otlp-origin"

    custom_origin_config {
      http_port              = 4318
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 60
    }
  }

  logging_config {
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "otlp/"
    include_cookies = false
  }

  default_cache_behavior {
    target_origin_id       = "otlp-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]

    # Disable caching for OTLP (POST requests)
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id

    compress = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-otlp-cf"
  }
}

# Managed cache policy - Caching Disabled
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

# Managed origin request policy - AllViewerExceptHostHeader
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

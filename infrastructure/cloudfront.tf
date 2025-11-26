# ============================================================================
# CLOUDFRONT DISTRIBUTION (CDN)
# ============================================================================

resource "aws_cloudfront_distribution" "frontend_distribution" {
  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"
  comment = "CDN for Secure File Share Frontend"

  # 1. Define the Origin (Where the content comes from)
  origin {
    # We use the S3 Website Endpoint (not the bucket ARN) as a Custom Origin
    domain_name = aws_s3_bucket_website_configuration.frontend_website.website_endpoint
    origin_id = "S3-Frontend-Origin"

    custom_origin_config {
      http_port = 80
      https_port = 443
      # S3 Website endpoints only support HTTP, so CloudFront connects via HTTP
      # but serves to the user via HTTPS.
      origin_protocol_policy = "http-only" 
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  # 2. Define how CloudFront handles requests
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend-Origin"

    # Forward all values (query strings, cookies) is not needed for static sites,
    # so we use a simplified cache policy.
    viewer_protocol_policy = "redirect-to-https" # Force users to use HTTPS
    
    # Performance settings (Compress files automatically)
    compress = true

    min_ttl = 0
    default_ttl = 3600  # Cache for 1 hour
    max_ttl = 86400 # Cache for 1 day

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # 3. Geographic Restrictions (Optional: No restrictions)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # 4. SSL Certificate (Use the default AWS one for *.cloudfront.net)
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
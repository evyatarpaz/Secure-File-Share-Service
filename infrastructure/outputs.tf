# Output the final public URL for testing
output "prod_url" {
  description = "The public URL of the Secure File Share API in prod stage"
  value = "${aws_api_gateway_stage.prod_stage.invoke_url}/files"
}

output "dev_url" {
  description = "The public URL of the Secure File Share API in dev stage"
  value = "${aws_api_gateway_stage.dev_stage.invoke_url}/files"
}

output "website_url" {
  description = "The public URL of your website"
  value = "http://${aws_s3_bucket_website_configuration.frontend_website.website_endpoint}"
}

output "cloudfront_url" {
  description = "The secure, public URL of your website via CloudFront"
  value = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}/${var.website_prefix}/"
}
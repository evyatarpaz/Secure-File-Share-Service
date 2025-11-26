# ============================================================================
# 1. S3 BUCKET FOR STATIC WEBSITE HOSTING
# ============================================================================

resource "aws_s3_bucket" "frontend_bucket" {
  bucket_prefix = "${var.project_name}-frontend-"
  force_destroy = true # Allows deleting bucket even if it contains files
}


# ============================================================================
# 2. PUBLIC ACCESS CONFIGURATION
# ============================================================================

# Disable "Block Public Access" to allow the world to see the website
resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
  
}

# Bucket Policy: Grant Read-Only permission to everyone (Principal: "*")
resource "aws_s3_bucket_policy" "frontend_policy" {
    bucket = aws_s3_bucket.frontend_bucket.id
    
    # Wait for the block to be disabled before applying policy
    depends_on = [aws_s3_bucket_public_access_block.frontend_public_access]

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Sid = "PublicReadGetObject"
            Effect = "Allow"
            Principal = "*"
            Action = ["s3:GetObject"]
            Resource = "${aws_s3_bucket.frontend_bucket.arn}/*"
        },
        ]
    })
  
}

# Enable Static Website Hosting on the bucket
resource "aws_s3_bucket_website_configuration" "frontend_website" {
    bucket = aws_s3_bucket.frontend_bucket.id
    
    index_document {
        suffix = "index.html"
    }
    
}


# ============================================================================
# 3. FILE UPLOADS (HTML, CSS, JS)
# ============================================================================

# ----------------------------------------------------------------------------
# A. Dynamic File Upload (index.html)
# ----------------------------------------------------------------------------
# We handle index.html separately because it requires 'templatefile' to inject
# the API Gateway URL directly into the code before uploading.
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.frontend_bucket.id
  key = "${var.website_prefix}/index.html"
  content_type = "text/html"

  # Inject the 'prod_url' variable into the template file
  content = templatefile("${path.module}/../frontend/index.html.tpl", {
    api_url = "${aws_api_gateway_stage.prod_stage.invoke_url}/files"
  })

  # Trigger an update if the template content OR the API URL changes
  etag = md5(templatefile("${path.module}/../frontend/index.html.tpl", {
    api_url = "${aws_api_gateway_stage.prod_stage.invoke_url}/files"
  }))
}

# ----------------------------------------------------------------------------
# B. Static Assets Loop (CSS, JS, Images)
# ----------------------------------------------------------------------------
# This resource uses 'for_each' to loop through the 'static_assets' variable map.
# It creates an S3 object for every item found in the map.
resource "aws_s3_object" "assets" {
  for_each = var.static_assets

  bucket = aws_s3_bucket.frontend_bucket.id
  
  # each.key is the filename (e.g., "style.css")
  key = "${var.website_prefix}/${each.key}"
  source = "${path.module}/../frontend/${each.key}"
  
  # each.value is the MIME type (e.g., "text/css")
  content_type = each.value

  # Calculate hash for each file to detect changes
  etag = filemd5("${path.module}/../frontend/${each.key}")
}
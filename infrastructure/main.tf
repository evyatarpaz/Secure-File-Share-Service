provider "aws" {
  region = var.aws_region
}

# ============================================================================
# 1. DATA & STORAGE LAYER (S3 & DynamoDB)
# ============================================================================


# S3 Bucket for storing the shared files
resource "aws_s3_bucket" "my_bucket" {
  bucket_prefix = "${var.project_name}-files-"
  force_destroy = true # Allows deleting bucket even if it contains files (Dev only)
}

# DynamoDB Table for file metadata (ID, Status, TTL)
resource "aws_dynamodb_table" "my_db" {
  name         = "FileMetaData"
  billing_mode = "PAY_PER_REQUEST" # Cost optimization: Pay only for usage
  hash_key     = "file_id"

  attribute {
    name = "file_id"
    type = "S" # String
  }
}

# ============================================================================
# 2. S3 CORS CONFIGURATION (FILE STORAGE)
# ============================================================================

resource "aws_s3_bucket_cors_configuration" "bucket_cors" {
  bucket = aws_s3_bucket.my_bucket.id

  cors_rule {
    # Allow the browser to send any header (Crucial for 'Content-Type' during uploads)
    allowed_headers = ["*"]
    
    # Allow necessary HTTP methods:
    # PUT  = For uploading files
    # GET  = For downloading files
    # POST = Required for some browser preflight checks
    # HEAD = Useful for checking file existence without downloading
    allowed_methods = ["PUT", "GET", "POST", "HEAD"]
    
    # Allow access from any domain (For development/demo purposes)
    # In a strict production environment, replace "*" with your specific domain.
    allowed_origins = ["*"]
    
    # Allow the frontend to see the ETag header (often used to verify uploads)
    expose_headers  = ["ETag"]
    
    # Cache the preflight response for 3000 seconds to reduce API calls
    max_age_seconds = 3000
  }
}

# Lifecycle Policy: Auto-delete files after 24 hours
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    id     = "delete-rule"
    status = "Enabled"
    expiration {
      days = 1
    }
  }
}

# ============================================================================
# 3. UPLOAD FEATURE STACK (Lambda & IAM)
# ============================================================================

# Package the Python code into a ZIP file
data "archive_file" "upload_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/upload_handler"
  output_path = "${path.module}/upload_lambda.zip"
}

# Create the Lambda Function
resource "aws_lambda_function" "upload_lambda" {
  filename         = data.archive_file.upload_lambda_zip.output_path
  function_name    = "GenerateUploadLink"
  role             = aws_iam_role.upload_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.upload_lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.my_db.name
      BUCKET_NAME = aws_s3_bucket.my_bucket.id
      MAX_FILE_SIZE_MB = var.max_file_size_mb
    }
  }
}

# ============================================================================
# 4. DOWNLOAD FEATURE STACK (Pending Implementation)
# ============================================================================

# Package the Python code into a ZIP file
data "archive_file" "download_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/download_handler"
  output_path = "${path.module}/download_lambda.zip"
}

# Create the Lambda Function

resource "aws_lambda_function" "download_lambda" {
  filename         = data.archive_file.download_lambda_zip.output_path
  function_name    = "GenerateDownloadLink"
  role             = aws_iam_role.download_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.download_lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.my_db.name
      BUCKET_NAME = aws_s3_bucket.my_bucket.id
    }
  }
}
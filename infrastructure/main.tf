provider "aws" {
  region = "us-east-1"
}

# ============================================================================
# 1. DATA & STORAGE LAYER (S3 & DynamoDB)
# ============================================================================

# S3 Bucket for storing the shared files
resource "aws_s3_bucket" "my_bucket" {
  bucket_prefix = "evyatar-files-"
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
# 2. S3 CONFIGURATION (Security & Lifecycle)
# ============================================================================

# CORS Configuration: Allow browser direct uploads
resource "aws_s3_bucket_cors_configuration" "bucket_cors" {
  bucket = aws_s3_bucket.my_bucket.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    allowed_origins = ["*"] # Note: Restrict this to your domain in production
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

# Step A: Package the Python code into a ZIP file
data "archive_file" "upload_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/upload_handler"
  output_path = "${path.module}/upload_lambda.zip"
}

# Step B: Define IAM Role (Identity) for the Upload Function
resource "aws_iam_role" "upload_role" {
  name = "secure_share_upload_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Step C: Define Permissions (Write-Only Access)
resource "aws_iam_role_policy" "upload_policy" {
  name = "upload_permissions"
  role = aws_iam_role.upload_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow writing to DB and S3
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "dynamodb:PutItem"
        ]
        Resource = [
          aws_dynamodb_table.my_db.arn,
          "${aws_s3_bucket.my_bucket.arn}/*"
        ]
      },
      {
        # Allow logging to CloudWatch
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Step D: Create the Lambda Function
resource "aws_lambda_function" "upload_lambda" {
  filename         = data.archive_file.upload_lambda_zip.output_path
  function_name    = "GenerateUploadLink"
  role             = aws_iam_role.upload_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.upload_lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.my_db.name
      BUCKET_NAME = aws_s3_bucket.my_bucket.id
    }
  }
}

# ============================================================================
# 4. DOWNLOAD FEATURE STACK (Pending Implementation)
# ============================================================================

# Step A: Package the Python code into a ZIP file
data "archive_file" "download_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/download_handler"
  output_path = "${path.module}/download_lambda.zip"
}

# Step B: Define IAM Role (Identity) for the Download Function
resource "aws_iam_role" "download_role" {
  name = "secure_share_download_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Step C: Define Permissions (Read & Update Access)
resource "aws_iam_role_policy" "download_policy" {
  name = "download_permissions"
  role = aws_iam_role.download_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = [
          aws_dynamodb_table.my_db.arn,
          "${aws_s3_bucket.my_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}


# Step D: Create the Lambda Function


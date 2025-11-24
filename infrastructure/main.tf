provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket_prefix = "evyatar-files-"
  force_destroy = true
}

resource "aws_dynamodb_table" "my_db" {
  name         = "FileMetaData"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "file_id"

  attribute {
    name = "file_id"
    type = "S"
  }
}

resource "aws_s3_bucket_cors_configuration" "bucket_cors" {
  bucket = aws_s3_bucket.my_bucket.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    allowed_origins = ["*"]
  }
}

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

data "archive_file" "upload_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/upload_handler"
  output_path = "${path.module}/upload_lambda.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "secure_file_share_role"

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

resource "aws_iam_role_policy" "upload_policy" {
  name = "secure_share_upload_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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

resource "aws_lambda_function" "upload_lambda" {
  filename = data.archive_file.upload_lambda_zip.output_path
  function_name = "GenerateUploadLink"
  role = aws_iam_role.lambda_role.arn
  handler = "app.lambda_handler"
  runtime = "python3.9"
  source_code_hash = data.archive_file.upload_lambda_zip.output_base64sha256
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.my_db.name
      BUCKET_NAME =aws_s3_bucket.my_bucket.id
    }
  }
}
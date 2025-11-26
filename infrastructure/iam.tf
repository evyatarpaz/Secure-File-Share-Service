# Define IAM Role (Identity) for the Upload Function
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

# Define Permissions (Write-Only Access)
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


# Define IAM Role (Identity) for the Download Function
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

# Define Permissions (Read & Update Access)
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
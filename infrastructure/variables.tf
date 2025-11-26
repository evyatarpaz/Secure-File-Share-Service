variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
  type        = string
}

variable "project_name" {
  description = "Project name prefix"
  default     = "secure-share"
  type        = string
}

# ============================================================================
# FRONTEND ASSETS CONFIGURATION
# ============================================================================

variable "static_assets" {
  description = "Map of static files to upload to S3. Key = Filename, Value = Content-Type"
  type        = map(string)

  default = {
    "style.css" = "text/css"
    "script.js" = "application/javascript"
  }
}

variable "website_prefix" {
  description = "The sub-folder within the bucket to host the website"
  type        = string
  default     = "evyatar-file-share-service"
}

variable "max_file_size_mb" {
  description = "Maximum allowed file size in Megabytes"
  type        = number
  default     = 10
}

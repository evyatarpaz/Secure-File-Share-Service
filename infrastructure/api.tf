# ============================================================================
# 1. API GATEWAY ROOT CONFIGURATION
# ============================================================================

# Define the main REST API container
resource "aws_api_gateway_rest_api" "file_share_api" {
  name        = "SecureFileShareAPI"
  description = "Public API for uploading and downloading one-time files"
}

# Define the "/files" path resource
# This creates the endpoint: https://[api-id].execute-api.[region].amazonaws.com/prod/files
resource "aws_api_gateway_resource" "files_resource" {
  rest_api_id = aws_api_gateway_rest_api.file_share_api.id
  parent_id   = aws_api_gateway_rest_api.file_share_api.root_resource_id
  path_part   = "files"
}

# ============================================================================
# 2. UPLOAD ENDPOINT (POST /files)
# ============================================================================

# Define HTTP Method: POST
# authorization is set to NONE, meaning the API is public
resource "aws_api_gateway_method" "upload_method" {
  rest_api_id   = aws_api_gateway_rest_api.file_share_api.id
  resource_id   = aws_api_gateway_resource.files_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration: Connects the API Method to the Lambda Function
resource "aws_api_gateway_integration" "upload_integration" {
  rest_api_id = aws_api_gateway_rest_api.file_share_api.id
  resource_id = aws_api_gateway_resource.files_resource.id
  http_method = aws_api_gateway_method.upload_method.http_method

  # AWS_PROXY: Pass the full HTTP request (headers, body) directly to Lambda
  type = "AWS_PROXY"

  # The backend Lambda always expects a POST request for invocation
  integration_http_method = "POST"
  uri                     = aws_lambda_function.upload_lambda.invoke_arn
}

# IAM Permission: Explicitly allow API Gateway to invoke the Upload Lambda
resource "aws_lambda_permission" "api_gateway_upload" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # Limit execution permission to this specific API to prevent unauthorized access
  source_arn = "${aws_api_gateway_rest_api.file_share_api.execution_arn}/*/*"
}

# ============================================================================
# 3. DOWNLOAD ENDPOINT (GET /files?file_id=...)
# ============================================================================

# Define HTTP Method: GET
resource "aws_api_gateway_method" "download_method" {
  rest_api_id   = aws_api_gateway_rest_api.file_share_api.id
  resource_id   = aws_api_gateway_resource.files_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integration: Connects the GET request to the Download Lambda
resource "aws_api_gateway_integration" "download_integration" {
  rest_api_id = aws_api_gateway_rest_api.file_share_api.id
  resource_id = aws_api_gateway_resource.files_resource.id
  http_method = aws_api_gateway_method.download_method.http_method

  type = "AWS_PROXY"

  # IMPORTANT: Even though the client sends a GET request, API Gateway must use 
  # POST to invoke the Lambda function. This is a Lambda requirement.
  integration_http_method = "POST"

  uri = aws_lambda_function.download_lambda.invoke_arn
}

# IAM Permission: Explicitly allow API Gateway to invoke the Download Lambda
resource "aws_lambda_permission" "api_gateway_download" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.download_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.file_share_api.execution_arn}/*/*"
}

# ============================================================================
# 4. DEPLOYMENT & OUTPUT
# ============================================================================

# Create a Deployment to make the API live
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.file_share_api.id

  # Trigger a new deployment if any of the methods or integrations change.
  # This uses a hash of the resources to detect changes.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.files_resource.id,
      aws_api_gateway_method.upload_method.id,
      aws_api_gateway_integration.upload_integration.id,
      aws_api_gateway_method.download_method.id,
      aws_api_gateway_integration.download_integration.id,
      aws_api_gateway_method.options_method.id,
      aws_api_gateway_integration.options_integration.id,
    ]))
  }

  # Ensure the new deployment is created before the old one is destroyed
  lifecycle {
    create_before_destroy = true
  }
}

# Define the "prod" stage for the deployment
resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id = aws_api_gateway_rest_api.file_share_api.id
  stage_name = "prod"
}

resource "aws_api_gateway_stage" "dev_stage" {
    deployment_id = aws_api_gateway_deployment.api_deployment.id
    rest_api_id = aws_api_gateway_rest_api.file_share_api.id
    stage_name = "dev"
  
}

resource "aws_api_gateway_method_settings" "prod_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.file_share_api.id
  stage_name  = aws_api_gateway_stage.prod_stage.stage_name
  
  # Apply settings to all methods in the stage
  method_path = "*/*"

  settings {
    # --- Throttling Settings (The Wallet Protector) ---

    # Rate Limit: How many requests per second are allowed on average?
    # Setting this to 10 means ~26 million requests per month. 
    throttling_rate_limit = 5
    # Burst Limit: How many requests can arrive in a short burst?
    throttling_burst_limit = 4
  }
}

# ============================================================================
# 5. CORS CONFIGURATION (The "Yes, you can enter" sign)
# ============================================================================

# 1. Create an OPTIONS method for the /files resource
resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.file_share_api.id
  resource_id   = aws_api_gateway_resource.files_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# 2. Create a Mock Integration (API Gateway answers directly, no Lambda needed)
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.file_share_api.id
  resource_id = aws_api_gateway_resource.files_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# 3. Define the Response (200 OK)
resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.file_share_api.id
  resource_id = aws_api_gateway_resource.files_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"
  
  # Define which headers are allowed in the response
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# 4. Fill the Response Headers with actual values
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.file_share_api.id
  resource_id = aws_api_gateway_resource.files_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  
  depends_on = [aws_api_gateway_integration.options_integration]
}
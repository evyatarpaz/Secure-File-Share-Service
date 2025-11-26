import json
import uuid
import os
import boto3

# Initialize AWS Clients outside the handler for performance
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])
MAX_SIZE_BYTES = int(os.environ.get('MAX_FILE_SIZE_MB', 10)) * 1024 * 1024

def lambda_handler(event, context):
    # Standard CORS headers for API Gateway response
    cors_headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
    }

    try:
        # 1. Parse the incoming JSON body
        # We use .get() to avoid crashes if body is missing
        body = json.loads(event.get('body', '{}'))
        
        # Extract metadata sent from frontend (defaults to generic if missing)
        original_filename = body.get('filename', 'downloaded_file')
        content_type = body.get('content_type', 'application/octet-stream')
        
        file_size = body.get('file_size', 0)
        if file_size > MAX_SIZE_BYTES:
            return {
                'statusCode': 400,
                'headers': cors_headers,
                'body': json.dumps({'message': f'File size exceeds the maximum limit of {MAX_SIZE_BYTES // (1024 * 1024)} MB'})
            }
        
        # Generate unique File ID
        file_id = str(uuid.uuid4())
        
        # 2. Persist metadata to DynamoDB
        table.put_item(Item={
            'file_id': file_id,
            'status': 'ACTIVE',
            'original_name': original_filename,  # Store the real name
            'content_type': content_type,         # Store the real MIME type
            'file_size': file_size                # Store the file size
        })
        
        # 3. Generate S3 Presigned URL for uploading
        # Note: We enforce 'application/octet-stream' for the upload process 
        # to avoid signature mismatch issues with S3.
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': os.environ['BUCKET_NAME'],
                'Key': file_id,
                'ContentType': 'application/octet-stream',
                'ContentLength': file_size
            },
            ExpiresIn=300 # URL valid for 5 minutes
        )
        
        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps({
                'file_id': file_id,
                'upload_url': presigned_url
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers,
            'body': json.dumps({'error': 'Internal Server Error'})
        }
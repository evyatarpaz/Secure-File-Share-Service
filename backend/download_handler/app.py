import json
import os
import boto3
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

# Define CORS headers globally
cors_headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
}

def lambda_handler(event, context):
    # 1. Extract File ID from Query Parameters
    try:
        file_id = event['queryStringParameters']['file_id']
    except (TypeError, KeyError):
        return {
            'statusCode': 400, 
            'headers': cors_headers, 
            'body': json.dumps({'message': 'Missing file_id'})
        }

    try:
        # 2. Atomic Update: Check status and update to DOWNLOADED
        # We use 'ReturnValues' to get the item attributes (metadata) 
        # in the same request, avoiding a second DB call.
        response = table.update_item(
            Key={'file_id': file_id},
            UpdateExpression='SET #s = :new_status',
            ConditionExpression='#s = :expected_status',
            ExpressionAttributeNames={'#s': 'status'},
            ExpressionAttributeValues={
                ':new_status': 'DOWNLOADED',
                ':expected_status': 'ACTIVE'
            },
            ReturnValues="ALL_NEW" # Returns the item after the update
        )
        
        # Extract original metadata from the DB response
        item = response.get('Attributes', {})
        original_name = item.get('original_name', 'file.bin')
        content_type = item.get('content_type', 'application/octet-stream')

    except ClientError as e:
        # Handle race conditions or invalid IDs
        error_code = e.response.get('Error', {}).get('Code')
        if error_code == 'ConditionalCheckFailedException':
            return {
                'statusCode': 403, 
                'headers': cors_headers, 
                'body': json.dumps({'message': 'Link expired or invalid'})
            }
        else:
            print(e)
            return {
                'statusCode': 500, 
                'headers': cors_headers, 
                'body': 'Internal Server Error'
            }

    # 3. Generate Download Link with Response Overrides
    # We tell S3 to force the browser to download the file with its original name.
    presigned_url = s3_client.generate_presigned_url(
        'get_object',
        Params={
            'Bucket': os.environ['BUCKET_NAME'],
            'Key': file_id,
            # Force download dialog with correct filename
            'ResponseContentDisposition': f'attachment; filename="{original_name}"',
            # Set the correct MIME type for the browser
            'ResponseContentType': content_type
        },
        ExpiresIn=300
    )

    # 4. Redirect user to the S3 URL
    # response_headers = cors_headers.copy()
    # response_headers['Location'] = presigned_url

    return {
        'statusCode': 200,
        'headers': cors_headers,
        'body': json.dumps({
            'download_url': presigned_url
        })
    }
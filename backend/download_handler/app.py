import json
import os
import boto3
from botocore.exceptions import ClientError

# Initialize AWS clients and resources outside the handler for re-use and faster performance
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])
    
def lambda_handler(event, context):
    try:
        # try to get the file_id from query parameters
        file_id = event['queryStringParameters']['file_id']
    # Handle the case where file_id is missing
    except TypeError:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Missing file_id parameter'})
        }
        
    try:
        # Attempt to update the status to DOWNLOADED only if current status is ACTIVE
        table.update_item(
            Key = {'file_id':file_id},
            UpdateExpression='SET #s = :new_status',
            ConditionExpression='#s = :expected_status',
            ExpressionAttributeNames={'#s': 'status'},
            ExpressionAttributeValues={
                ':new_status': 'DOWNLOADED',
                ':expected_status': 'ACTIVE'
            }
        )
    # Handle the case where the condition fails
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', '')
        if error_code == 'ConditionalCheckFailedException':
            return {
                'statusCode': 403,
                'body': json.dumps({'message': 'This link has already been used or is invalid.'})
            }
        else:
            print(e)
            return {'statusCode': 500, 'body': 'Internal Server Error'}
    
    # Generate a presigned URL for the S3 object
    presigned_url = s3_client.generate_presigned_url('get_object',
                                                     Params={
                                                         'Bucket': os.environ['BUCKET_NAME'],
                                                         'Key': file_id
                                                     },
                                                     ExpiresIn=300)
    return {
            'statusCode': 302,
            'headers': {
                'Location': presigned_url
            }
        }
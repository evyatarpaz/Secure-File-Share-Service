import json
import uuid
import os
import boto3

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])
    
def lambda_handler(event, context):
    file_id = str(uuid.uuid4())
    table.put_item(Item={
        'file_id': file_id,
        'status': 'ACTIVE'
    })
    presigned_url = s3_client.generate_presigned_url('put_object',
                                                     Params={
                                                         'Bucket': os.environ['BUCKET_NAME'],
                                                         'Key': file_id
                                                     },
                                                     ExpiresIn=300)
    return {
        'statusCode': 200,
        'body': json.dumps({
            'file_id': file_id,
            'upload-url': presigned_url
        })
    }

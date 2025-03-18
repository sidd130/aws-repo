import boto3
from botocore.config import Config
import json

import boto3.s3

def lambda_handler(event, context):
    print(event['Records'][0]['body'])
    print(context)
    file_name = 'request_' + event['Records'][0]['body']["uniqueID"] + '.json'
    with open(file=file_name,mode="w") as file_handle:
        file_handle.write(event['Records'][0]['body'])
    config = Config(region_name='ap-south-1')
    s3_client = boto3.client('s3',config=config)
    resp = s3_client.put_object(
        Body=file_name,
        Bucket='event-storage-bucket-20250319',
        Key=file_name
    )
    print(resp)


    
import boto3
from botocore.config import Config
import json
import maskpass

access_key = maskpass.askpass('Enter Access Key: ')
secret_access_key = maskpass.askpass('Enter Secret Access Key: ')
config = Config(region_name='ap-south-1')
sqs_client = boto3.client('sqs',
                          aws_access_key_id=access_key,
                          aws_secret_access_key=secret_access_key,
                          config=config)
response = sqs_client.send_message(
    QueueUrl='event-collector-queue',
    MessageBody=json.dumps({"Status": 200})
    )
print(response)

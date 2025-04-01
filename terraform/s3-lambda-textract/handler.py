# import boto3
import json
import os


def lambda_handler(event, context):
    print(event['Records'])
    print(os.getenv('AWS_REGION'))
    print(os.getenv('S3_BUCKET_NAME'))
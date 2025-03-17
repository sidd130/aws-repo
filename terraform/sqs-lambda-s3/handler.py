import json

def lambda_handler(event, context):
    print(event['Records'][0]['body'])
    print(context)
    
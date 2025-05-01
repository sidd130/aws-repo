import json
import datetime

def lambda_handler(event, context):
    resp = {}
    resp["time"] = str(datetime.datetime.now())
    print(event)
    print(context)
    print(resp)
    final_response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": resp
    }
    return json.dumps(final_response)
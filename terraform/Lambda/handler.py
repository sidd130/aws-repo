import json

def lambda_handler(event, context):
    print(str(event))
    print(str(context))
    resp = {
        "status": 200
    }

    return json.dumps(resp)
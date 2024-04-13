import json

def lambda_handler(event, context):
    print(str(event))
    print(str(context))
    resp = {
        "status": 200,
        "msg": "Info message from Lambda"
    }

    return json.dumps(resp)
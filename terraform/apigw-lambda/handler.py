import json
import datetime

def lambda_handler(event, context):
    resp = {}
    resp["time"] = str(datetime.datetime.now())
    print(event)
    print(context)
    print(resp)
    return json.dumps(resp)
import json
import datetime

def lambda_handler(event, context):
    resp = {}
    resp["time"] = str(datetime.datetime.now())
    print(resp)
    return json.dumps(resp)
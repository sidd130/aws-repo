import json
import datetime

def lambda_handler(event, context):
    resp = {}
    resp["time"] = str(datetime.datetime.now())
    return json.dumps(resp)
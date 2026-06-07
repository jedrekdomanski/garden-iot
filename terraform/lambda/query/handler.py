import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ["DYNAMODB_TABLE"]
DEVICE_ID = "esp32-garden"


def handler(event, context):
    params = event.get("queryStringParameters") or {}
    limit = int(params.get("limit", 500))

    table = dynamodb.Table(TABLE_NAME)
    kwargs = {
        "KeyConditionExpression": Key("device_id").eq(DEVICE_ID),
        "ScanIndexForward": False,
        "Limit": limit,
    }

    if "from" in params:
        kwargs["KeyConditionExpression"] &= Key("ingested_at").gte(params["from"])
    if "to" in params:
        kwargs["KeyConditionExpression"] &= Key("ingested_at").lte(params["to"])

    result = table.query(**kwargs)
    items = sorted(result["Items"], key=lambda x: x["ingested_at"])

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(items, default=str),
    }

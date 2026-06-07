import json
import os
import boto3
from datetime import datetime, timezone, timedelta

dynamodb = boto3.resource("dynamodb")
eventbridge = boto3.client("events")

TABLE_NAME = os.environ["DYNAMODB_TABLE"]
EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]
DEVICE_ID = "esp32-garden"
TTL_DAYS = 365


def handler(event, context):
    body = json.loads(event.get("body") or "{}")

    ingested_at = datetime.now(timezone.utc).isoformat()
    expires_at = int((datetime.now(timezone.utc) + timedelta(days=TTL_DAYS)).timestamp())

    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item={
        "device_id": DEVICE_ID,
        "ingested_at": ingested_at,
        "expires_at": expires_at,
        **body,
    })

    eventbridge.put_events(Entries=[{
        "Source": "garden.iot",
        "DetailType": body.get("event", "unknown"),
        "Detail": json.dumps({**body, "ingested_at": ingested_at}),
        "EventBusName": EVENT_BUS_NAME,
    }])

    return {"statusCode": 200, "body": "ok"}

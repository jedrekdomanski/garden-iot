import json
import os
import boto3

ses = boto3.client("ses")

ALERT_EMAIL = os.environ["ALERT_EMAIL"]


def handler(event, context):
    detail = event.get("detail", {})
    date = detail.get("date", "unknown")
    time = detail.get("time", "unknown")
    moisture = detail.get("moisture_percent", "N/A")

    ses.send_email(
        Source=ALERT_EMAIL,
        Destination={"ToAddresses": [ALERT_EMAIL]},
        Message={
            "Subject": {"Data": f"🚨 Garden: Low humidity alert — {moisture}%"},
            "Body": {"Text": {"Data": f"Soil moisture is critically low.\n\nMoisture: {moisture}%\nTime: {date} {time}\n\nConsider checking your irrigation system."}},
        },
    )

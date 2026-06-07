import os

API_KEY = os.environ["API_KEY"]


def handler(event, context):
    provided_key = event.get("identitySource", [None])[0] if isinstance(event.get("identitySource"), list) \
        else event.get("headers", {}).get("x-api-key")
    return {"isAuthorized": provided_key == API_KEY}

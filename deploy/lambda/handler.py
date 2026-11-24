"""AWS Lambda entry point. Same model, same predict() -- different front door."""
import json
from app.main import Flower, predict


def handler(event, context):
    # Works for a Lambda Function URL or API Gateway (body is a JSON string),
    # and for a direct `aws lambda invoke` (event is the flower itself).
    body = event.get("body", event)
    if isinstance(body, str):
        body = json.loads(body)
    result = predict(Flower(**body))
    return {"statusCode": 200, "body": json.dumps(result)}

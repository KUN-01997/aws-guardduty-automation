import os
import json
import boto3
from botocore.exceptions import ClientError

sns = boto3.client('sns')
dynamodb = boto3.resource('dynamodb')

SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
DEDUP_TABLE = os.environ.get('DEDUP_TABLE')

def lambda_handler(event, context):
    finding_id = event.get("id", "unknown-id")

    # Reference the DynamoDB table
    table = dynamodb.Table(DEDUP_TABLE)

    # Check if this finding ID already exists
    try:
        response = table.get_item(Key={'finding_id': finding_id})
        if 'Item' in response:
            print(f"Duplicate finding {finding_id} — skipping alert.")
            return {"status": "duplicate_skipped"}
    except ClientError as e:
        print(f"DynamoDB get_item error: {e}")

    # Save the finding to DynamoDB
    try:
        table.put_item(Item={"finding_id": finding_id})
    except ClientError as e:
        print(f"DynamoDB put_item error: {e}")
        return {"status": "dynamodb_put_failed"}

    # Send alert to SNS
    detail = event.get("detail", {})
    message = f"""GuardDuty Alert
Title: {detail.get('title')}
Type: {detail.get('type')}
Severity: {detail.get('severity')}
Resource: {detail.get('resource', {}).get('instanceDetails', {}).get('instanceId', 'N/A')}
"""

    try:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="⚠️ GuardDuty Finding Detected",
            Message=message
        )
    except ClientError as e:
        print(f"SNS publish error: {e}")
        return {"status": "sns_publish_failed"}

    print(f"Alert sent for finding {finding_id}")
    return {"status": "alert_sent"}

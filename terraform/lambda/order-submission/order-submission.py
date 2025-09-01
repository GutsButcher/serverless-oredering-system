import json
import boto3
import os
import uuid
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

def convert_float_to_decimal(obj):
    """Convert float values to Decimal for DynamoDB compatibility"""
    if isinstance(obj, list):
        return [convert_float_to_decimal(item) for item in obj]
    elif isinstance(obj, dict):
        return {k: convert_float_to_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, float):
        return Decimal(str(obj))
    else:
        return obj

def lambda_handler(event, context):
    try:
        # Handle both proxy and non-proxy integration
        if 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event
        
        order_id = str(uuid.uuid4())
        
        # Convert float values to Decimal for DynamoDB
        items_with_decimal = convert_float_to_decimal(body['items'])
        
        # Save to DynamoDB
        table = dynamodb.Table('orders')
        table.put_item(Item={
            'orderId': order_id,
            'customerEmail': body['customerEmail'],
            'items': items_with_decimal,
            'status': 'PENDING',
            'createdAt': datetime.utcnow().isoformat()
        })
        
        # Send to payment queue
        sqs.send_message(
            QueueUrl=os.environ['PAYMENT_QUEUE_URL'],
            MessageBody=json.dumps({'orderId': order_id, 'customerEmail': body['customerEmail']})
        )
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'orderId': order_id, 'status': 'PENDING'})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }

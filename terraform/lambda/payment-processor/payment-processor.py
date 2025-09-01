import json
import boto3
import random
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

def lambda_handler(event, context):
    for record in event['Records']:
        message = json.loads(record['body'])
        order_id = message['orderId']
        
        # Simulate payment (90% success)
        success = random.random() < 0.9
        status = 'PAYMENT_APPROVED' if success else 'PAYMENT_FAILED'
        
        # Update order
        table = dynamodb.Table('orders')
        table.update_item(
            Key={'orderId': order_id},
            UpdateExpression='SET #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': status}
        )
        
        # Send to next queue if successful
        if success:
            sqs.send_message(
                QueueUrl=os.environ['INVENTORY_QUEUE_URL'],
                MessageBody=json.dumps(message)
            )
        
        print(f"Order {order_id}: {status}")

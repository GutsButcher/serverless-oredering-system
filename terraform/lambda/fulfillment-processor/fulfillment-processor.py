import json
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    for record in event['Records']:
        message = json.loads(record['body'])
        order_id = message['orderId']
        
        # Update to shipped
        table = dynamodb.Table('orders')
        table.update_item(
            Key={'orderId': order_id},
            UpdateExpression='SET #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'SHIPPED'}
        )
        
        print(f"Order {order_id}: SHIPPED")

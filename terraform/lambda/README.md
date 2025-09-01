# Lambda Functions

Each function handles a specific part of the order processing pipeline.

## Functions Overview

### order-submission
Entry point for new orders. Validates input, stores in DynamoDB, kicks off processing.

**Triggers**: API Gateway POST /orders  
**Outputs**: Order ID, sends message to payment queue

### order-status
Fetches current order details from DynamoDB.

**Triggers**: API Gateway GET /orders/{orderId}  
**Outputs**: Full order details with current status

### payment-processor
Simulates payment processing (always succeeds in this demo).

**Triggers**: Payment SQS queue  
**Outputs**: Updates order status, sends to inventory queue

### inventory-processor
Checks stock availability (always has stock in this demo).

**Triggers**: Inventory SQS queue  
**Outputs**: Updates order, sends to fulfillment queue

### fulfillment-processor
Final step - marks order as shipped.

**Triggers**: Fulfillment SQS queue  
**Outputs**: Updates order status to SHIPPED

## Local Testing

Each function can be tested locally:

```python
# Create test event
event = {
    "body": json.dumps({
        "customerEmail": "test@example.com",
        "items": [{"name": "Widget", "price": 29.99, "quantity": 1}]
    })
}

# Run function
from order_submission import lambda_handler
result = lambda_handler(event, {})
print(result)
```

## Environment Variables

Functions expect these environment vars (auto-configured by Terraform):
- `PAYMENT_QUEUE_URL`
- `INVENTORY_QUEUE_URL`
- `FULFILLMENT_QUEUE_URL`

## Adding New Functions

1. Create new directory with Python file
2. Add to `main.tf` (data archive + lambda function)
3. Set up triggers (SQS, API Gateway, etc)
4. Deploy with terraform apply

## Notes

- All functions use Python 3.9 runtime
- DynamoDB requires Decimal type for numbers (not float)
- Each function has full DynamoDB/SQS access via IAM role
- Logs go to CloudWatch automatically
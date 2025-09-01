# Serverless Order Processing System

AWS serverless architecture for handling e-commerce orders with automatic payment processing, inventory management, and fulfillment.

## Architecture

The system uses event-driven processing with SQS queues connecting Lambda functions:

```
API Gateway → Order Submission → Payment Queue → Payment Processor
                     ↓                              ↓
                DynamoDB                    Inventory Queue
                                                    ↓
                                          Inventory Processor
                                                    ↓
                                          Fulfillment Queue
                                                    ↓
                                          Fulfillment Processor
```

## Quick Start

```bash
# Deploy everything
./deploy.sh

# Test the API
./test-api.sh
```

## Components

### API Gateway
- `POST /orders` - Submit new orders
- `GET /orders/{orderId}` - Check order status

### Lambda Functions
- **order-submission**: Validates orders, saves to DynamoDB, triggers payment processing
- **payment-processor**: Handles payment logic, updates order status
- **inventory-processor**: Manages stock levels, triggers fulfillment
- **fulfillment-processor**: Ships orders, updates final status

### Storage & Messaging
- **DynamoDB**: Orders table with order details and status
- **SQS Queues**: Payment, inventory, and fulfillment message queues

## Development

### Prerequisites
- AWS CLI configured
- Terraform 1.0+
- Python 3.9

### Project Structure
```
.
├── terraform/          # Infrastructure as code
│   ├── lambda/        # Lambda function code
│   └── *.tf           # Terraform configs
├── deploy.sh          # Deployment script
└── test-api.sh        # API testing script
```

### Deployment

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Testing

After deployment, grab the API URL:
```bash
terraform output api_gateway_invoke_url
```

Submit a test order:
```bash
curl -X POST https://YOUR_API_URL/orders \
  -H "Content-Type: application/json" \
  -d '{"customerEmail": "test@example.com", "items": [{"name": "Widget", "price": 29.99, "quantity": 2}]}'
```

## Configuration

All infrastructure settings are in `terraform/variables.tf`. Default region is `us-east-1`.

## Monitoring

Check Lambda logs in CloudWatch under `/aws/lambda/{function-name}`.

## License

MIT
# Terraform Configuration

Infrastructure as Code for the serverless ordering system.

## Files

- `main.tf` - Core resources (Lambda, DynamoDB, SQS, API Gateway)
- `variables.tf` - Configuration variables
- `outputs.tf` - Useful outputs (URLs, ARNs)
- `terraform.tf` - Provider requirements

## Quick Commands

```bash
# First time setup
terraform init

# Check what will change
terraform plan

# Deploy everything
terraform apply

# Tear down
terraform destroy
```

## Key Resources

### DynamoDB
- Table: `orders`
- Partition key: `orderId`
- Billing: Pay-per-request

### SQS Queues
- payment-queue
- inventory-queue
- fulfillment-queue

### Lambda Functions
All functions use the same IAM role with:
- DynamoDB full access
- SQS full access
- CloudWatch logs

### API Gateway
REST API with:
- POST /orders
- GET /orders/{orderId}
- Stage: prod

## Customization

Edit `variables.tf` to change:
- AWS region (default: us-east-1)
- Add more configuration options as needed

## State Management

Currently uses local state. For production, consider:
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state"
    key    = "ordering-system/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Troubleshooting

If deployment fails:
1. Check AWS credentials: `aws sts get-caller-identity`
2. Verify region: `aws configure get region`
3. Check terraform version: `terraform version` (need 1.0+)
4. Review error logs in `terraform apply` output
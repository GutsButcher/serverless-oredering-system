# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Terraform Commands

### Essential Commands
```bash
# Initialize Terraform (required before any other operation)
terraform init

# Format Terraform files to canonical style
terraform fmt -recursive

# Validate configuration syntax
terraform validate

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# Destroy infrastructure
terraform destroy
```

### State Management
```bash
# Show current state
terraform show

# List resources in state
terraform state list

# Refresh state with actual infrastructure
terraform refresh
```

## Architecture Overview

This Terraform configuration manages AWS infrastructure for a serverless ordering system:

### Core Resources
- **DynamoDB Table**: `orders` table with orderId as hash key (PAY_PER_REQUEST billing)
- **SQS Queues**: Three message queues for event-driven processing:
  - `payment-queue`: Handles payment processing events
  - `inventory-queue`: Manages inventory update events  
  - `fulfillment-queue`: Processes order fulfillment events

### Configuration Structure
- `terraform.tf`: Provider requirements (AWS ~> 5.0, Terraform >= 1.0)
- `main.tf`: Resource definitions for DynamoDB and SQS queues
- `variables.tf`: Configuration variables (aws_region defaults to us-east-1)
- `outputs.tf`: References undefined IAM role resources (lambda_role) - needs completion

### Important Notes
- The outputs.tf file references `aws_iam_role.lambda_role` which is not yet defined in the configuration
- All resources are tagged with Project = "serverless-ordering-system"
- Uses PAY_PER_REQUEST billing mode for DynamoDB (serverless, no capacity planning needed)
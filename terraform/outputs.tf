# Output the role ARN for reference
output "lambda_role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.lambda_role.arn
}

# Output the role name for reference
output "lambda_role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.lambda_role.name
}

# Output SQS Queue URLs
output "payment_queue_url" {
  description = "URL of the payment SQS queue"
  value       = aws_sqs_queue.payment_queue.url
}

output "inventory_queue_url" {
  description = "URL of the inventory SQS queue"
  value       = aws_sqs_queue.inventory_queue.url
}

output "fulfillment_queue_url" {
  description = "URL of the fulfillment SQS queue"
  value       = aws_sqs_queue.fulfillment_queue.url
}

# API Gateway outputs
output "api_gateway_invoke_url" {
  description = "Invoke URL for the API Gateway stage"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/orders"
}

output "api_gateway_base_url" {
  description = "Base URL for the API Gateway"
  value       = aws_api_gateway_stage.prod.invoke_url
}

# Test command output for creating order
output "test_curl_command" {
  description = "Sample curl command to test the API"
  value = <<-EOT
    # Create a new order:
    curl -X POST ${aws_api_gateway_stage.prod.invoke_url}/orders \
    -H "Content-Type: application/json" \
    -d '{
      "customerEmail": "test@example.com",
      "items": [{"name": "Widget", "price": 29.99, "quantity": 2}]
    }'
  EOT
}

# Test command output for checking order status
output "test_status_check_command" {
  description = "Sample curl command to check order status"
  value = <<-EOT
    # Check order status (replace ORDER_ID with actual order ID):
    curl -X GET ${aws_api_gateway_stage.prod.invoke_url}/orders/ORDER_ID
  EOT
}
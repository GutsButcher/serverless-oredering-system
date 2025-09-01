provider "aws" {
  region = var.aws_region
}

# create dynamoDB table named 'orders'
resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "orders"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "orderId"

  attribute {
    name = "orderId"
    type = "S"
  }

  tags = {
    Name        = "orders"
    Project = "serverless-ordering-system"
  }
}

# create 3 SQS-queue
resource "aws_sqs_queue" "payment_queue" {
  name                      = "payment-queue"

  tags = {
    Name        = "payment-queue"
    Project = "serverless-ordering-system"
  }

}

resource "aws_sqs_queue" "inventory_queue" {
  name                      = "inventory-queue"

  tags = {
    Name        = "inventory-queue"
    Project = "serverless-ordering-system"
  }

}
resource "aws_sqs_queue" "fulfillment_queue" {
  name                      = "fulfillment-queue"

  tags = {
    Name        = "fulfillment-queue"
    Project = "serverless-ordering-system"
  }

}

############################################# IAM ROLE #################################################################
########################################################################################################################
########################################################################################################################
# IAM Role for Lambda with DynamoDB, SQS, and SNS access
resource "aws_iam_role" "lambda_role" {
  name               = "lambda-dynamodb-sqs-sns-role"
  description        = "IAM role for Lambda with DynamoDB, SQS, and SNS full access"
  
  # Trust policy allowing Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "lambda-dynamodb-sqs-sns-role"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Attach AWSLambdaBasicExecutionRole policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach AmazonDynamoDBFullAccess policy
resource "aws_iam_role_policy_attachment" "dynamodb_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Attach AmazonSQSFullAccess policy
resource "aws_iam_role_policy_attachment" "sqs_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

# Attach AmazonSNSFullAccess policy
resource "aws_iam_role_policy_attachment" "sns_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}


########################################################################################################################
########################################################################################################################
########################################################################################################################


# CREATE FIRST LAMBDA FUNCTION in ./terraform/lambda/order-submission/order-submission.py

# point to codes
data "archive_file" "order_submission" {
  type        = "zip"
  output_path = "./lambda/order-submission.zip"
  source_dir = "./lambda/order-submission"
}
data "archive_file" "payment_processor" {
  type        = "zip"
  output_path = "./lambda/payment-processor.zip"
  source_dir = "./lambda/payment-processor"
}
data "archive_file" "inventory_processor" {
  type        = "zip"
  output_path = "./lambda/inventory-processor.zip"
  source_dir = "./lambda/inventory-processor"
}
data "archive_file" "fulfillment_processor" {
  type        = "zip"
  output_path = "./lambda/fulfillment-processor.zip"
  source_dir = "./lambda/fulfillment-processor"
}
data "archive_file" "order_status" {
  type        = "zip"
  output_path = "./lambda/order-status.zip"
  source_dir = "./lambda/order-status"
}

resource "aws_lambda_function" "order_submission" {
    filename         = data.archive_file.order_submission.output_path
    function_name    = "order-submission"
    role            = aws_iam_role.lambda_role.arn
    handler         = "order-submission.lambda_handler"  # filename.exportedFunction
    source_code_hash = data.archive_file.order_submission.output_base64sha256
    runtime         = "python3.9"     # or python3.11, etc.
    
    environment {
      variables = {
        PAYMENT_QUEUE_URL = aws_sqs_queue.payment_queue.url
        INVENTORY_QUEUE_URL = aws_sqs_queue.inventory_queue.url
        FULFILLMENT_QUEUE_URL = aws_sqs_queue.fulfillment_queue.url
      }
    }
  }
resource "aws_lambda_function" "payment_processor" {
    filename         = data.archive_file.payment_processor.output_path
    function_name    = "payment-processor"
    role            = aws_iam_role.lambda_role.arn
    handler         = "payment-processor.lambda_handler"  # filename.exportedFunction
    source_code_hash = data.archive_file.payment_processor.output_base64sha256
    runtime         = "python3.9"     # or python3.11, etc.
    
    environment {
      variables = {
        INVENTORY_QUEUE_URL = aws_sqs_queue.inventory_queue.url
      }
    }
  }
resource "aws_lambda_function" "inventory_processor" {
    filename         = data.archive_file.inventory_processor.output_path
    function_name    = "inventory-processor"
    role            = aws_iam_role.lambda_role.arn
    handler         = "inventory-processor.lambda_handler"  # filename.exportedFunction
    source_code_hash = data.archive_file.inventory_processor.output_base64sha256
    runtime         = "python3.9"     # or python3.11, etc.
    
    environment {
      variables = {
        FULFILLMENT_QUEUE_URL = aws_sqs_queue.fulfillment_queue.url
      }
    }
  }
resource "aws_lambda_function" "fulfillment_processor" {
    filename         = data.archive_file.fulfillment_processor.output_path
    function_name    = "fulfillment-processor"
    role            = aws_iam_role.lambda_role.arn
    handler         = "fulfillment-processor.lambda_handler"  # filename.exportedFunction
    source_code_hash = data.archive_file.fulfillment_processor.output_base64sha256
    runtime         = "python3.9"     # or python3.11, etc.
  
  }

# Lambda function for checking order status
resource "aws_lambda_function" "order_status" {
    filename         = data.archive_file.order_status.output_path
    function_name    = "order-status"
    role            = aws_iam_role.lambda_role.arn
    handler         = "order-status.lambda_handler"
    source_code_hash = data.archive_file.order_status.output_base64sha256
    runtime         = "python3.9"
  }

########################################################################################################################
##################################### SQS TRIGGERS FOR LAMBDA FUNCTIONS ################################################
########################################################################################################################

# Event source mapping for payment processor - triggered by payment queue
resource "aws_lambda_event_source_mapping" "payment_queue_trigger" {
  event_source_arn = aws_sqs_queue.payment_queue.arn
  function_name    = aws_lambda_function.payment_processor.function_name
  batch_size       = 10  # Number of messages to process at once (max 10 for standard queues)
  enabled          = true
}

# Event source mapping for inventory processor - triggered by inventory queue
resource "aws_lambda_event_source_mapping" "inventory_queue_trigger" {
  event_source_arn = aws_sqs_queue.inventory_queue.arn
  function_name    = aws_lambda_function.inventory_processor.function_name
  batch_size       = 10
  enabled          = true
}

# Event source mapping for fulfillment processor - triggered by fulfillment queue
resource "aws_lambda_event_source_mapping" "fulfillment_queue_trigger" {
  event_source_arn = aws_sqs_queue.fulfillment_queue.arn
  function_name    = aws_lambda_function.fulfillment_processor.function_name
  batch_size       = 10
  enabled          = true
}

########################################################################################################################
############################################# API GATEWAY ##############################################################
########################################################################################################################

# Create REST API
resource "aws_api_gateway_rest_api" "order_api" {
  name        = "order-api"
  description = "API for order submission"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = {
    Name    = "order-api"
    Project = "serverless-ordering-system"
  }
}

# Create /orders resource
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  parent_id   = aws_api_gateway_rest_api.order_api.root_resource_id
  path_part   = "orders"
}

# Create POST method for /orders
resource "aws_api_gateway_method" "orders_post" {
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda integration for POST /orders
resource "aws_api_gateway_integration" "orders_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"  # Lambda Proxy integration
  uri                     = aws_lambda_function.order_submission.invoke_arn
}

# Create /orders/{orderId} resource for GET method
resource "aws_api_gateway_resource" "order_by_id" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  parent_id   = aws_api_gateway_resource.orders.id
  path_part   = "{orderId}"
}

# Create GET method for /orders/{orderId}
resource "aws_api_gateway_method" "order_get" {
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  resource_id   = aws_api_gateway_resource.order_by_id.id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda integration for GET /orders/{orderId}
resource "aws_api_gateway_integration" "order_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  resource_id = aws_api_gateway_resource.order_by_id.id
  http_method = aws_api_gateway_method.order_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_status.invoke_arn
}

# Lambda permission for API Gateway to invoke the order submission function
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_submission.function_name
  principal     = "apigateway.amazonaws.com"
  
  # The source ARN for the permission
  source_arn = "${aws_api_gateway_rest_api.order_api.execution_arn}/*/*"
}

# Lambda permission for API Gateway to invoke the order status function
resource "aws_lambda_permission" "api_gateway_invoke_status" {
  statement_id  = "AllowAPIGatewayInvokeStatus"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_status.function_name
  principal     = "apigateway.amazonaws.com"
  
  # The source ARN for the permission
  source_arn = "${aws_api_gateway_rest_api.order_api.execution_arn}/*/*"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "order_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  
  # This ensures deployment happens after all the methods and integrations are created
  depends_on = [
    aws_api_gateway_method.orders_post,
    aws_api_gateway_integration.orders_post_integration,
    aws_api_gateway_method.order_get,
    aws_api_gateway_integration.order_get_integration
  ]
  
  # Force new deployment when configuration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.orders.id,
      aws_api_gateway_method.orders_post.id,
      aws_api_gateway_integration.orders_post_integration.id,
      aws_api_gateway_resource.order_by_id.id,
      aws_api_gateway_method.order_get.id,
      aws_api_gateway_integration.order_get_integration.id
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage (prod)
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.order_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  stage_name    = "prod"
  
  tags = {
    Name    = "prod"
    Project = "serverless-ordering-system"
  }
}

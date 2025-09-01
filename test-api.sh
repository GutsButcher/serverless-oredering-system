#!/bin/bash

set -e

cd terraform

API_URL=$(terraform output -raw api_gateway_invoke_url 2>/dev/null)

if [ -z "$API_URL" ]; then
    echo "Error: No API URL found. Run ./deploy.sh first"
    exit 1
fi

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customerEmail": "test@example.com",
    "items": [
      {"name": "Widget", "price": 29.99, "quantity": 2},
      {"name": "Gadget", "price": 49.99, "quantity": 1}
    ]
  }')

ORDER_ID=$(echo $RESPONSE | grep -o '"orderId":"[^"]*' | cut -d'"' -f4)

if [ -z "$ORDER_ID" ]; then
    echo "Error: Failed to create order"
    echo "$RESPONSE"
    exit 1
fi

sleep 2

curl -s -X GET "${API_URL}/${ORDER_ID}" | python3 -m json.tool
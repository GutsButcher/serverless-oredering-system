#!/bin/bash

# Quick API test script

set -e

cd terraform

echo "🧪 Testing Order API..."
echo

# Get API URL
API_URL=$(terraform output -raw api_gateway_invoke_url)

if [ -z "$API_URL" ]; then
    echo "❌ No API URL found. Deploy first with ./deploy.sh"
    exit 1
fi

echo "📮 Submitting test order to: $API_URL"
echo

# Submit order
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customerEmail": "test@example.com",
    "items": [
      {"name": "Widget", "price": 29.99, "quantity": 2},
      {"name": "Gadget", "price": 49.99, "quantity": 1}
    ]
  }')

echo "Response: $RESPONSE"
echo

# Extract order ID
ORDER_ID=$(echo $RESPONSE | grep -o '"orderId":"[^"]*' | cut -d'"' -f4)

if [ -z "$ORDER_ID" ]; then
    echo "❌ Failed to create order"
    exit 1
fi

echo "✅ Order created: $ORDER_ID"
echo

# Check status
echo "📊 Checking order status..."
sleep 2

STATUS_URL="${API_URL}/${ORDER_ID}"
curl -s -X GET "$STATUS_URL" | python3 -m json.tool

echo
echo "✨ Test complete!"
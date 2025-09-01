#!/bin/bash

# Deploy serverless ordering system

set -e

echo "🚀 Deploying Serverless Ordering System..."
echo

cd terraform

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install terraform first."
    exit 1
fi

# Initialize terraform if needed
if [ ! -d ".terraform" ]; then
    echo "📦 Initializing Terraform..."
    terraform init
    echo
fi

# Format check
echo "🎨 Checking formatting..."
terraform fmt -recursive
echo

# Validate configuration
echo "✅ Validating configuration..."
terraform validate
echo

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan
echo

# Ask for confirmation
read -p "Deploy infrastructure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Apply changes
echo "🔨 Applying changes..."
terraform apply tfplan
rm tfplan

echo
echo "✨ Deployment complete!"
echo

# Show outputs
echo "📌 API Endpoints:"
terraform output api_gateway_invoke_url
echo
echo "Test with:"
terraform output -raw test_curl_command
echo
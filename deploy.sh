#!/bin/bash

set -e

cd terraform

if ! command -v terraform &> /dev/null; then
    echo "Error: terraform not found"
    exit 1
fi

if [ ! -d ".terraform" ]; then
    terraform init
fi

terraform fmt -recursive > /dev/null
terraform validate > /dev/null

terraform plan -out=tfplan

read -p "Deploy? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

terraform apply tfplan
rm tfplan

echo "Deployment complete"
echo
terraform output api_gateway_invoke_url
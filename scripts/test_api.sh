#!/bin/bash

API_URL=$(cd terraform && terraform output -raw api_gateway_url)

echo "Testing User Registration API"
echo "API URL: $API_URL"
echo ""

echo "Test 1: Create new user (should succeed)"
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "email": "alice@example.com"}' \
  -w "\nStatus: %{http_code}\n\n"

sleep 2

echo "Test 2: Duplicate user (should fail with 409)"
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "email": "alice@example.com"}' \
  -w "\nStatus: %{http_code}\n\n"

sleep 2

echo "Test 3: Missing fields (should fail with 400)"
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"username": "bob"}' \
  -w "\nStatus: %{http_code}\n\n"

echo "Test 4: Create another user"
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"username": "bob", "email": "bob@example.com"}' \
  -w "\nStatus: %{http_code}\n\n"
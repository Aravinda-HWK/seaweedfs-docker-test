#!/bin/bash

set -e

echo "🚀 SeaweedFS Docker Test Script"
echo "================================"

# Load environment variables
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  Warning: .env file not found. Using default credentials."
    export S3_ACCESS_KEY="raven"
    export S3_SECRET_KEY="raven-secret"
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Step 1: Start Docker containers
echo -e "\n${BLUE}Step 1: Starting SeaweedFS containers...${NC}"
docker-compose up -d

# Step 2: Wait for services to be ready
echo -e "\n${BLUE}Step 2: Waiting for services to be ready...${NC}"
sleep 5

# Check if master is ready
echo "Checking Master service..."
for i in {1..30}; do
    if curl -s http://localhost:9333/cluster/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Master is ready${NC}"
        break
    fi
    echo "Waiting for master... ($i/30)"
    sleep 1
done

# Check if volume is ready
echo "Checking Volume service..."
for i in {1..30}; do
    if curl -s http://localhost:8080/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Volume is ready${NC}"
        break
    fi
    echo "Waiting for volume... ($i/30)"
    sleep 1
done

# Check if S3 is ready
echo "Checking S3 service..."
for i in {1..30}; do
    if curl -s http://localhost:8333 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ S3 is ready${NC}"
        break
    fi
    echo "Waiting for S3... ($i/30)"
    sleep 1
done

# Step 3: Run Go test
echo -e "\n${BLUE}Step 3: Running Go test program...${NC}"
go mod tidy
go run main.go

# Step 4: Test with AWS CLI (if available)
if command -v aws &> /dev/null; then
    echo -e "\n${BLUE}Step 4: Testing with AWS CLI...${NC}"
    
    # Create test file
    echo "Test attachment from AWS CLI" > test-cli.txt
    
    # Upload
    echo "Uploading file..."
    aws --endpoint-url http://localhost:8333 \
        --region us-east-1 \
        s3 cp test-cli.txt s3://email-attachments/cli-test/test-cli.txt \
        --no-sign-request \
        2>/dev/null || \
    AWS_ACCESS_KEY_ID=raven AWS_SECRET_ACCESS_KEY=raven-secret \
    aws --endpoint-url http://localhost:8333 \
        --region us-east-1 \
        s3 cp test-cli.txt s3://email-attachments/cli-test/test-cli.txt
    
    echo -e "${GREEN}✅ CLI upload successful${NC}"
    
    # Download
    echo "Downloading file..."
    AWS_ACCESS_KEY_ID=raven AWS_SECRET_ACCESS_KEY=raven-secret \
    aws --endpoint-url http://localhost:8333 \
        --region us-east-1 \
        s3 cp s3://email-attachments/cli-test/test-cli.txt downloaded-cli.txt
    
    echo -e "${GREEN}✅ CLI download successful${NC}"
    echo "Content: $(cat downloaded-cli.txt)"
    
    # Clean up
    rm -f test-cli.txt downloaded-cli.txt
else
    echo -e "\n${BLUE}Step 4: Skipping AWS CLI test (not installed)${NC}"
fi

echo -e "\n${GREEN}🎉 All tests completed successfully!${NC}"
echo -e "\n${BLUE}Services are running at:${NC}"
echo "  Master:  http://localhost:9333"
echo "  Volume:  http://localhost:8080"
echo "  S3 API:  http://localhost:8333"
echo -e "\n${BLUE}To stop services:${NC}"
echo "  docker-compose down"
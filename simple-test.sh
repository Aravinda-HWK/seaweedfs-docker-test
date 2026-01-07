#!/bin/bash

set -e

echo "🚀 Simple SeaweedFS Test"
echo "========================"

# Load environment variables
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  Warning: .env file not found. Using default credentials."
    export S3_ACCESS_KEY="raven"
    export S3_SECRET_KEY="raven-secret"
fi

# Step 1: Restart containers
echo "Restarting containers..."
docker-compose down
docker-compose up -d

# Step 2: Wait for services
echo "Waiting for services..."
sleep 8

# Step 3: Check what's running
echo -e "\n📊 Service Status:"
docker ps --filter "name=seaweedfs"

# Step 4: Check S3 logs
echo -e "\n📋 S3 Logs:"
docker logs seaweedfs-s3

# Step 5: Check S3 status
echo -e "\n🔧 Checking S3 service..."
sleep 5
docker logs seaweedfs-s3 2>&1 | tail -n 5

# Step 6: Test with curl
echo -e "\n🧪 Testing endpoints:"
echo "Master: $(curl -s http://localhost:9333/dir/status | jq -r '.Topology.DataCenters[0].Racks[0].DataNodes[0].Url' 2>/dev/null || echo 'OK')"
echo "Volume: $(curl -s http://localhost:8080/status 2>/dev/null && echo 'OK' || echo 'Not responding')"
echo "Filer: $(curl -s http://localhost:8888/ 2>/dev/null && echo 'OK' || echo 'Not responding')"
echo "S3: $(curl -s -w '%{http_code}' http://localhost:8333 2>/dev/null || echo 'Not responding')"

# Step 7: Run Go test
echo -e "\n🔧 Installing Go dependencies..."
go mod tidy

echo -e "\n▶️  Running Go test..."
go run main.go
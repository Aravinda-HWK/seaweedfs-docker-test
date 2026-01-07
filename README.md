# SeaweedFS Docker Test Project

A complete Docker setup for testing SeaweedFS S3-compatible object storage with file upload/download capabilities using Go.

## 📋 Table of Contents

- [About](#about)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Running the Project](#running-the-project)
- [Testing](#testing)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

## 🎯 About

This project demonstrates how to:
- Set up SeaweedFS distributed file storage using Docker
- Configure S3-compatible API access
- Upload, download, list, and delete files using Go
- Test S3 operations with AWS SDK for Go v2

SeaweedFS is a fast distributed storage system for blobs, objects, files, and data lake, optimized for billions of files.

## ✅ Prerequisites

Before running this project, ensure you have:

### Required
- **Docker** (v20.10 or later) - [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** (v2.0 or later) - Usually comes with Docker Desktop
- **Go** (v1.21 or later) - [Install Go](https://golang.org/dl/)

### Optional
- **AWS CLI** (v2.x) - For testing S3 operations via command line (optional, but recommended)
- **Git** - For cloning the repository

Verify required installations:
```bash
docker --version
docker-compose --version
go version
```

### Installing AWS CLI (Optional but Recommended)

The AWS CLI allows you to interact with SeaweedFS S3 API from the command line. While the Go program handles all testing, AWS CLI is useful for manual operations.

#### macOS

**Option 1: Using Homebrew (Recommended)**
```bash
brew install awscli
```

**Option 2: Official Installer**
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
rm AWSCLIV2.pkg
```

#### Linux

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
```

#### Windows

Download and run the installer:
```
https://awscli.amazonaws.com/AWSCLIV2.msi
```

#### Verify AWS CLI Installation

```bash
aws --version
# Should output: aws-cli/2.x.x ...
```

> **Note**: AWS CLI is optional. If not installed, the test script will skip Step 4 (AWS CLI tests) but all core functionality will still work via the Go program.

## 📁 Project Structure

```
seaweedfs-docker-test/
├── docker-compose.yaml   # Docker services configuration (master, volume, filer, s3)
├── s3-config.json       # S3 credentials and bucket configuration
├── main.go              # Go test program for S3 operations
├── go.mod               # Go module dependencies
├── go.sum               # Go module checksums
├── .env                 # Environment variables (credentials) - DO NOT COMMIT
├── .env.example         # Environment variables template - SAFE TO COMMIT
├── .gitignore          # Git ignore configuration
├── test.sh              # Automated test script with health checks
├── simple-test.sh       # Simple test script
├── diagnose.sh          # Diagnostic script for troubleshooting
├── view-file.sh         # Script to view uploaded files
└── README.md            # This file
```

## 🚀 Quick Start

### 1. Clone or Download the Project

```bash
# If using Git
git clone <your-repo-url>
cd seaweedfs-docker-test

# Or download and extract the ZIP file
```

### 2. Setup Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your preferred editor
nano .env
# Or
code .env
```

Add your credentials (for local testing, use the defaults):
```env
S3_ACCESS_KEY=raven
S3_SECRET_KEY=raven-secret
```

> **Note**: The `.env` file is git-ignored for security. Never commit credentials to version control!

### 3. Make Scripts Executable

```bash
chmod +x test.sh simple-test.sh diagnose.sh view-file.sh
```

### 4. Run the Automated Test

```bash
./test.sh
```

This will:
- Start all SeaweedFS Docker containers
- Wait for services to be healthy
- Run the Go test program
- Show you upload/download results

## 🏃 Running the Project

### Option 1: Using the Test Script (Recommended)

```bash
# Runs everything automatically
./test.sh
```

### Option 2: Manual Step-by-Step

#### Step 1: Start SeaweedFS Services

```bash
# Start all services in detached mode
docker-compose up -d

# Check that all containers are running
docker-compose ps
```

You should see 4 services running:
- `seaweedfs-master` (ports 9333, 19333)
- `seaweedfs-volume` (ports 8080, 18080)
- `seaweedfs-filer` (ports 8888, 18888)
- `seaweedfs-s3` (port 8333)

#### Step 2: Wait for Services to Be Ready

```bash
# Wait about 10 seconds for all services to start
sleep 10

# Verify services are responding
curl http://localhost:9333/cluster/status  # Master
curl http://localhost:8080/status          # Volume
curl http://localhost:8888/                # Filer
curl http://localhost:8333/                # S3
```

#### Step 3: Install Go Dependencies

```bash
go mod download
```

#### Step 4: Run the Go Test Program

```bash
# Make sure environment variables are loaded
source .env

# Run the program
go run main.go
```

Expected output:
```
📦 Creating bucket...
✅ Bucket created successfully

📤 Uploading test file...
✅ File uploaded: test/1736186400/test-file.txt

📥 Downloading test file...
✅ File downloaded: Hello from SeaweedFS! This is a test attachment.

📋 Listing objects in bucket...
Found 1 objects:
  - test/1736186400/test-file.txt (size: 49 bytes)
```

## 🧪 Testing

### Run All Tests
```bash
./test.sh
```

This will run:
- **Step 1**: Start Docker containers
- **Step 2**: Wait for services to be healthy
- **Step 3**: Run Go test program (upload/download/list/delete)
- **Step 4**: Test with AWS CLI (only if installed)

### Simple Test (No Health Checks)
```bash
./simple-test.sh
```

### Diagnose Issues
```bash
./diagnose.sh
```

### Manual Testing with AWS CLI

If you have AWS CLI installed, you can manually interact with SeaweedFS:

```bash
# Set credentials
export AWS_ACCESS_KEY_ID=raven
export AWS_SECRET_ACCESS_KEY=raven-secret

# List buckets
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 ls

# List files in bucket
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 ls s3://email-attachments/

# Upload a file
echo "Test content" > test.txt
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 cp test.txt s3://email-attachments/test.txt

# Download a file
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 cp s3://email-attachments/test.txt downloaded.txt

# Delete a file
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 rm s3://email-attachments/test.txt

# Remove bucket (must be empty)
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 rb s3://email-attachments
```

### View Container Logs
```bash
# View all logs
docker-compose logs

# View specific service logs
docker logs seaweedfs-master
docker logs seaweedfs-volume
docker logs seaweedfs-filer
docker logs seaweedfs-s3

# Follow logs in real-time
docker-compose logs -f
```

## ⚙️ Configuration

### S3 Credentials

Credentials are configured in two places:

1. **Server-side** (`s3-config.json`):
```json
{
  "identities": [
    {
      "name": "raven",
      "credentials": [
        {
          "accessKey": "raven",
          "secretKey": "raven-secret"
        }
      ],
      "actions": ["Admin", "Read", "Write"]
    }
  ]
}
```

2. **Client-side** (`.env` file):
```env
S3_ACCESS_KEY=raven
S3_SECRET_KEY=raven-secret
```

### Ports

| Service | Port | Description |
|---------|------|-------------|
| Master  | 9333 | Master server API |
| Master  | 19333 | Master gRPC |
| Volume  | 8080 | Volume server API |
| Volume  | 18080 | Volume gRPC |
| Filer   | 8888 | Filer HTTP API |
| Filer   | 18888 | Filer gRPC |
| S3      | 8333 | S3 API endpoint |

### Bucket Configuration

- Default bucket name: `email-attachments`
- Change in `main.go` if needed (line 21):
```go
bucket = "your-bucket-name"
```

## 🔧 Troubleshooting

### Services Won't Start

```bash
# Check if ports are already in use
lsof -i :9333
lsof -i :8080
lsof -i :8888
lsof -i :8333

# Stop existing containers
docker-compose down

# Remove volumes and restart fresh
docker-compose down -v
docker-compose up -d
```

### Connection Refused Errors

```bash
# Wait longer for services to initialize
sleep 15

# Check service health
docker-compose ps

# Check if containers are healthy
docker inspect seaweedfs-master | grep Health -A 10
```

### Upload/Download Failures

```bash
# Check S3 service logs
docker logs seaweedfs-s3

# Verify bucket exists
curl http://localhost:8333/

# Check filer logs
docker logs seaweedfs-filer
```

### Environment Variables Not Loaded

```bash
# Manually export variables
export S3_ACCESS_KEY=raven
export S3_SECRET_KEY=raven-secret

# Then run
go run main.go
```

### Clean Slate Restart

```bash
# Stop all containers and remove volumes
docker-compose down -v

# Remove any leftover data
docker volume prune

# Start fresh
docker-compose up -d
sleep 15
go run main.go
```

## 📦 What the Go Program Does

The `main.go` program demonstrates:

1. **Create S3 Client** - Connects to SeaweedFS S3 API
2. **Create Bucket** - Creates `email-attachments` bucket
3. **Upload File** - Uploads a test file with timestamp-based path
4. **Download File** - Retrieves and verifies the uploaded file
5. **List Objects** - Shows all files in the bucket
6. **Delete File** (commented out) - Clean up test files

## 🛑 Stopping the Project

```bash
# Stop containers (keeps data)
docker-compose stop

# Stop and remove containers (keeps data)
docker-compose down

# Stop, remove containers AND delete all data
docker-compose down -v
```

## 📝 Notes

- Files are stored in Docker volumes: `seaweedfs-volume` and `seaweedfs-filer`
- Data persists between container restarts unless volumes are removed
- S3 API is compatible with AWS SDK v2
- Default region is `us-east-1` (can be changed in `main.go`)

## 🔗 Useful Resources

- [SeaweedFS Documentation](https://github.com/seaweedfs/seaweedfs/wiki)
- [SeaweedFS S3 API](https://github.com/seaweedfs/seaweedfs/wiki/Amazon-S3-API)
- [AWS SDK for Go v2](https://aws.github.io/aws-sdk-go-v2/)

## 📄 License

See LICENSE file for details.

---

**Happy testing with SeaweedFS! 🌊**

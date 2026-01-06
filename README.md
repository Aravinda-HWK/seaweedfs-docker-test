# SeaweedFS Docker Test Project

Complete Docker setup for testing SeaweedFS with file upload/download capabilities.

## 📁 Project Structure

```
seaweedfs-test/
├── docker-compose.yml    # Docker services configuration
├── s3-config.json        # S3 credentials configuration
├── main.go              # Go test program
├── go.mod               # Go dependencies
├── .env                 # Environment variables (DO NOT commit)
├── .env.example         # Environment variables template
├── .gitignore          # Git ignore file
├── test.sh              # Automated test script
└── README.md            # This file
```

## 🚀 Quick Start

### 1. Create Project Directory

```bash
mkdir seaweedfs-test
cd seaweedfs-test
```

### 2. Create All Files

Copy the following files from the artifacts:
- `docker-compose.yml`
- `s3-config.json`
- `main.go`
- `go.mod`
- `test.sh`

### 3. Setup Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Edit .env and add your credentials
# S3_ACCESS_KEY=your-access-key
# S3_SECRET_KEY=your-secret-key
```

For local testing, the default credentials in `s3-config.json` are:
- Access Key: `raven`
- Secret Key: `raven-secret`

### 4. Make Test Script Executable

```bash
chmod +x test.sh
```

### 5. Run Tests

```bash
./test.sh
```

## 🔧 Manual Setup

### Start Services

```bash
docker-compose up -d
```

Wait for services to start (about 5-10 seconds), then verify:

```bash
# Check master
curl http://localhost:9333/cluster/status

# Check volume
curl http://localhost:8080/status

# Check S3
curl http://localhost:8333
```

### Run Go Test Program

```bash
go mod download
go run main.go
```

### Test with AWS CLI (Optional)

```bash
# Configure credentials
export AWS_ACCESS_KEY_ID=raven
export AWS_SECRET_ACCESS_KEY=raven-secret

# Create bucket
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 mb s3://email-attachments

# Upload file
echo "Test attachment" > test.txt
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 cp test.txt s3://email-attachments/test.txt

# Download file
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 cp s3://email-attachments/test.txt downloaded.txt

# List files
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 ls s3://email-attachments/
```

## 📊 Service Endpoints

| Service | Port | URL |
|---------|------|-----|
| Master | 9333 | http://localhost:9333 |
| Volume | 8080 | http://localhost:8080 |
| Filer | 8888 | http://localhost:8888 |
| S3 API | 8333 | http://localhost:8333 |

## 🔐 Credentials

- **Access Key**: `raven`
- **Secret Key**: `raven-secret`
- **Region**: `us-east-1`
- **Bucket**: `email-attachments`

## 🧪 What the Test Does

The Go test program performs the following operations:

1. ✅ Creates bucket (`email-attachments`)
2. ✅ Uploads a test file
3. ✅ Downloads the file
4. ✅ Lists all objects in bucket
5. ✅ Deletes the test file

## 📦 Docker Services

### Master Server
- Manages cluster metadata
- Port: 9333

### Volume Server
- Stores actual file data
- Port: 8080
- Data persisted in Docker volume

### Filer Server
- Provides file system interface
- Port: 8888
- Required for S3 gateway
- Data persisted in Docker volume

### S3 Gateway
- Provides S3-compatible API
- Port: 8333
- Configured with credentials from `s3-config.json`
- Connects to filer backend

## 🛑 Stop Services

```bash
docker-compose down
```

To remove data volume as well:

```bash
docker-compose down -v
```

## 🔍 Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs master
docker-compose logs volume
docker-compose logs s3
```

### Connection refused errors
Wait a few more seconds for services to fully initialize, then try again.

### Port already in use
Change ports in `docker-compose.yml`:
```yaml
ports:
  - "9334:9333"  # Change 9333 to 9334
```

## 📚 Next Steps

After successful testing, you can:
- Integrate this setup into your Raven email system
- Add attachment metadata tracking in SQLite
- Implement streaming downloads for IMAP
- Add virus scanning before upload
- Configure multi-node setup for production

## 🔗 Useful Links

- [SeaweedFS Documentation](https://github.com/seaweedfs/seaweedfs/wiki)
- [AWS SDK for Go v2](https://aws.github.io/aws-sdk-go-v2/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 💡 Tips

- The S3 gateway uses path-style URLs (not virtual-hosted)
- All data is stored in the `seaweedfs-data` Docker volume
- For production, use separate machines for master and volume servers
- Consider using a load balancer for multiple volume servers
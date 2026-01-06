package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

const (
	endpoint = "http://localhost:8333"
	region   = "us-east-1"
	bucket   = "email-attachments"
)

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func main() {
	ctx := context.Background()

	// Create S3 client
	client := createS3Client()

	// Test 1: Create bucket
	fmt.Println("📦 Creating bucket...")
	if err := createBucket(ctx, client); err != nil {
		log.Printf("⚠️  Bucket creation failed (might already exist): %v\n", err)
	} else {
		fmt.Println("✅ Bucket created successfully")
	}

	// Wait a moment for bucket to be ready
	time.Sleep(1 * time.Second)

	// Test 2: Upload file
	fmt.Println("\n📤 Uploading test file...")
	testData := []byte("Hello from SeaweedFS! This is a test attachment.")
	key := fmt.Sprintf("test/%d/test-file.txt", time.Now().Unix())
	
	if err := uploadFile(ctx, client, key, testData); err != nil {
		log.Fatalf("❌ Upload failed: %v", err)
	}
	fmt.Printf("✅ File uploaded: %s\n", key)

	// Test 3: Download file
	fmt.Println("\n📥 Downloading test file...")
	downloaded, err := downloadFile(ctx, client, key)
	if err != nil {
		log.Fatalf("❌ Download failed: %v", err)
	}
	fmt.Printf("✅ File downloaded: %s\n", string(downloaded))

	// Test 4: List objects
	fmt.Println("\n📋 Listing objects in bucket...")
	if err := listObjects(ctx, client); err != nil {
		log.Fatalf("❌ List failed: %v", err)
	}

	// // Test 5: Delete file
	fmt.Println("\n🗑️  Deleting test file...")
	if err := deleteFile(ctx, client, key); err != nil {
		log.Fatalf("❌ Delete failed: %v", err)
	}
	fmt.Printf("✅ File deleted: %s\n", key)

	fmt.Println("\n🎉 All tests passed!")
}

func createS3Client() *s3.Client {
	accessKey := getEnv("S3_ACCESS_KEY", "")
	secretKey := getEnv("S3_SECRET_KEY", "")

	if accessKey == "" || secretKey == "" {
		log.Fatal("❌ S3_ACCESS_KEY and S3_SECRET_KEY environment variables must be set")
	}

	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
			accessKey,
			secretKey,
			"",
		)),
	)
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	return s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(endpoint)
		o.UsePathStyle = true
	})
}

func createBucket(ctx context.Context, client *s3.Client) error {
	_, err := client.CreateBucket(ctx, &s3.CreateBucketInput{
		Bucket: aws.String(bucket),
	})
	return err
}

func uploadFile(ctx context.Context, client *s3.Client, key string, data []byte) error {
	_, err := client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucket),
		Key:         aws.String(key),
		Body:        bytes.NewReader(data),
		ContentType: aws.String("text/plain"),
	})
	return err
}

func downloadFile(ctx context.Context, client *s3.Client, key string) ([]byte, error) {
	result, err := client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return nil, err
	}
	defer result.Body.Close()

	return io.ReadAll(result.Body)
}

func listObjects(ctx context.Context, client *s3.Client) error {
	result, err := client.ListObjectsV2(ctx, &s3.ListObjectsV2Input{
		Bucket: aws.String(bucket),
	})
	if err != nil {
		return err
	}

	fmt.Printf("Found %d objects:\n", len(result.Contents))
	for _, obj := range result.Contents {
		fmt.Printf("  - %s (size: %d bytes)\n", *obj.Key, obj.Size)
	}
	return nil
}

func deleteFile(ctx context.Context, client *s3.Client, key string) error {
	_, err := client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})
	return err
}
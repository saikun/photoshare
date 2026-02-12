package handlers

import (
	"backend/db"
	"context"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func UploadPhoto(c *gin.Context) {
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file is received"})
		return
	}

	// S3 Upload
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion("ap-northeast-1"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to load SDK config"})
		return
	}
	s3Client := s3.NewFromConfig(cfg)
	bucketName := os.Getenv("S3_BUCKET_NAME")
	if bucketName == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "S3 Data Bucket not configured"})
		return
	}

	ext := filepath.Ext(file.Filename)
	newFilename := uuid.New().String() + ext

	f, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to open file"})
		return
	}
	defer f.Close()

	_, err = s3Client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(bucketName),
		Key:         aws.String(newFilename),
		Body:        f,
		ContentType: aws.String(file.Header.Get("Content-Type")),
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload to S3"})
		return
	}

	// Save to DynamoDB
	photoID := uuid.New().String()
	url := "https://" + bucketName + ".s3.ap-northeast-1.amazonaws.com/" + newFilename
	createdAt := time.Now().Format(time.RFC3339)

	_, err = db.Client.PutItem(context.TODO(), &dynamodb.PutItemInput{
		TableName: aws.String("Photos"),
		Item: map[string]types.AttributeValue{
			"id":        &types.AttributeValueMemberS{Value: photoID},
			"url":       &types.AttributeValueMemberS{Value: url},
			"filename":  &types.AttributeValueMemberS{Value: newFilename},
			"createdAt": &types.AttributeValueMemberS{Value: createdAt},
		},
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save metadata"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "File uploaded successfully",
		"url":     url,
	})
}

package handlers

import (
	"backend/db"
	"backend/models"
	"context"
	"net/http"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/gin-gonic/gin"
)

func GetFeed(c *gin.Context) {
	out, err := db.Client.Scan(context.TODO(), &dynamodb.ScanInput{
		TableName: aws.String("Photos"),
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var photos []models.Photo
	for _, item := range out.Items {
		photo := models.Photo{
			ID:        item["id"].(*types.AttributeValueMemberS).Value,
			URL:       item["url"].(*types.AttributeValueMemberS).Value,
			Filename:  item["filename"].(*types.AttributeValueMemberS).Value,
			CreatedAt: item["createdAt"].(*types.AttributeValueMemberS).Value,
		}
		photos = append(photos, photo)
	}

	c.JSON(http.StatusOK, photos)
}

package handlers

import (
	"backend/db"
	"backend/models"
	"context"
	"fmt"
	"net/http"
	"sort"

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
		fav := 0
		if val, ok := item["favorites"]; ok {
			if n, ok := val.(*types.AttributeValueMemberN); ok {
				// simple parsing, ignore error for now
				// in real app use strconv.Atoi
				fmt.Sscanf(n.Value, "%d", &fav)
			}
		}

		photo := models.Photo{
			ID:        item["id"].(*types.AttributeValueMemberS).Value,
			URL:       item["url"].(*types.AttributeValueMemberS).Value,
			Filename:  item["filename"].(*types.AttributeValueMemberS).Value,
			CreatedAt: item["createdAt"].(*types.AttributeValueMemberS).Value,
			Favorites: fav,
		}
		photos = append(photos, photo)
	}

	// Sort by Favorites desc
	sort.Slice(photos, func(i, j int) bool {
		return photos[i].Favorites > photos[j].Favorites
	})

	c.JSON(http.StatusOK, photos)
}

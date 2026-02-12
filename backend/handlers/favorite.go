package handlers

import (
	"backend/db"
	"context"
	"net/http"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/gin-gonic/gin"
)

func IncrementFavorite(c *gin.Context) {
	id := c.Param("id")

	// Atomic counter update
	input := &dynamodb.UpdateItemInput{
		TableName: aws.String("Photos"),
		Key: map[string]types.AttributeValue{
			"id": &types.AttributeValueMemberS{Value: id},
		},
		UpdateExpression: aws.String("SET favorites = if_not_exists(favorites, :zero) + :incr"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":zero": &types.AttributeValueMemberN{Value: "0"},
			":incr": &types.AttributeValueMemberN{Value: "1"},
		},
		ReturnValues: types.ReturnValueUpdatedNew,
	}

	out, err := db.Client.UpdateItem(context.TODO(), input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update favorites"})
		return
	}

	newFavorites := "0"
	if val, ok := out.Attributes["favorites"]; ok {
		if n, ok := val.(*types.AttributeValueMemberN); ok {
			newFavorites = n.Value
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Favorite added",
		"favorites": newFavorites,
	})
}

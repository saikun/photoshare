package models

type Photo struct {
	ID        string `json:"id" dynamodbav:"id"`
	URL       string `json:"url" dynamodbav:"url"`
	Filename  string `json:"filename" dynamodbav:"filename"`
	CreatedAt string `json:"createdAt" dynamodbav:"createdAt"`
	Favorites int    `json:"favorites" dynamodbav:"favorites"`
}

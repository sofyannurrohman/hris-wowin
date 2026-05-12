package main

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	err := godotenv.Load("../../.env")
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"), os.Getenv("DB_NAME"), os.Getenv("DB_PORT"))

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal(err)
	}

	var indices []struct {
		IndexName string
		IsUnique  bool
	}
	db.Raw(`
		SELECT
			indexname,
			CASE WHEN indexdef LIKE '%UNIQUE%' THEN true ELSE false END as is_unique
		FROM
			pg_indexes
		WHERE
			tablename = 'product_transfers'
	`).Scan(&indices)

	fmt.Println("Indices on product_transfers:")
	for _, idx := range indices {
		fmt.Printf("- %s (Unique: %v)\n", idx.IndexName, idx.IsUnique)
	}
}

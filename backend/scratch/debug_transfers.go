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

	var count int64
	db.Table("product_transfers").Count(&count)
	fmt.Printf("Total transfers: %d\n", count)

	var transfers []struct {
		ID              string
		DeliveryOrderNo string
		ProductID       string
	}
	db.Table("product_transfers").Order("created_at desc").Limit(10).Scan(&transfers)

	fmt.Println("Recent transfers:")
	for _, t := range transfers {
		fmt.Printf("- ID: %s, DO: %s, Product: %s\n", t.ID, t.DeliveryOrderNo, t.ProductID)
	}
}

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

	fmt.Println("Dropping problematic index...")
	db.Exec("DROP INDEX IF EXISTS idx_product_transfers_delivery_order_no CASCADE")
	db.Exec("ALTER TABLE product_transfers DROP CONSTRAINT IF EXISTS idx_product_transfers_delivery_order_no CASCADE")
	
	var results []struct {
		IndexName string `gorm:"column:indexname"`
	}
	db.Raw("SELECT indexname FROM pg_indexes WHERE tablename = 'product_transfers'").Scan(&results)

	fmt.Println("Indices remaining on product_transfers:")
	for _, r := range results {
		fmt.Println("-", r.IndexName)
	}
}

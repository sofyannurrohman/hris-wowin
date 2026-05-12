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

	fmt.Println("Dropping unique index...")
	db.Exec("DROP INDEX IF EXISTS idx_product_transfers_delivery_order_no CASCADE")
	
	fmt.Println("Creating non-unique index...")
	db.Exec("CREATE INDEX idx_product_transfers_delivery_order_no ON product_transfers(delivery_order_no)")
	
	fmt.Println("Done.")
}

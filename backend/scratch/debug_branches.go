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

	var transfers []struct {
		ID              string
		DeliveryOrderNo string
		Status          string
		ToBranchID      string
		FromFactoryID   string
	}
	db.Table("product_transfers").Order("created_at desc").Limit(10).Scan(&transfers)

	fmt.Println("Recent transfers with Branch/Factory IDs:")
	for _, t := range transfers {
		fmt.Printf("- ID: %s, DO: %s, Status: %s, ToBranch: %s, FromFactory: %s\n", 
			t.ID, t.DeliveryOrderNo, t.Status, t.ToBranchID, t.FromFactoryID)
	}

	var branches []struct {
		ID   string
		Name string
	}
	db.Table("branches").Scan(&branches)
	fmt.Println("\nAvailable Branches:")
	for _, b := range branches {
		fmt.Printf("- %s: %s\n", b.ID, b.Name)
	}
}

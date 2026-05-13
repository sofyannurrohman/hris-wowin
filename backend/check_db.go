package main

import (
	"fmt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	dsn := "host=localhost user=postgres password=postgres dbname=hris_wowin_dev port=5432 sslmode=disable TimeZone=UTC"
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("failed to connect database")
	}

	var hasColumn bool
	db.Raw("SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='sales_orders' AND column_name='payment_status')").Scan(&hasColumn)
	fmt.Printf("Has payment_status: %v\n", hasColumn)
}

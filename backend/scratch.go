package main

import (
	"fmt"
	"log"
	
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	dsn := "host=localhost user=postgres password=postgres dbname=hris_db port=5432 sslmode=disable"
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal(err)
	}

	var leaveTypes []domain.LeaveType
	db.Find(&leaveTypes)
	fmt.Println("--- LEAVE TYPES ---")
	for _, lt := range leaveTypes {
		fmt.Printf("ID: %s, Name: %s, ReqQuota: %v\n", lt.ID, lt.Name, lt.RequiresQuota)
	}

	var balances []domain.LeaveBalance
	db.Preload("LeaveType").Find(&balances)
	fmt.Println("\n--- LEAVE BALANCES ---")
	for _, b := range balances {
		name := "nil"
		req := false
		if b.LeaveType != nil {
			name = b.LeaveType.Name
			req = b.LeaveType.RequiresQuota
		}
		fmt.Printf("EmpID: %s, LTID: %s, Name: %s, ReqQuota: %v\n", b.EmployeeID, b.LeaveTypeID, name, req)
	}
}

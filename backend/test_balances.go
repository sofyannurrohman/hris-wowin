package main

import (
    "encoding/json"
    "fmt"
    "github.com/sofyan/hris_wowin/backend/internal/domain"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

func main() {
    dsn := "host=localhost user=root password=secretpassword dbname=hris_db port=5321 sslmode=disable TimeZone=Asia/Jakarta"
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        panic(err)
    }

    var balances []*domain.LeaveBalance
    err = db.Preload("LeaveType").Where("year = ?", 2026).Find(&balances).Error
    if err != nil {
        panic(err)
    }

    type LeaveBalanceResponse struct {
        LeaveTypeID   string `json:"leave_type_id"`
        LeaveTypeName string `json:"leave_type_name"`
        IsPaid        bool   `json:"is_paid"`
        RequiresQuota bool   `json:"requires_quota"`
    }

    var res []LeaveBalanceResponse
    for _, b := range balances {
        name := ""
        isPaid := true
        requiresQuota := true
        if b.LeaveType != nil {
            name = b.LeaveType.Name
            isPaid = b.LeaveType.IsPaid
            requiresQuota = b.LeaveType.RequiresQuota
        }
        res = append(res, LeaveBalanceResponse{
            LeaveTypeID:   b.LeaveTypeID.String(),
            LeaveTypeName: name,
            IsPaid:        isPaid,
            RequiresQuota: requiresQuota,
        })
    }

    b, _ := json.MarshalIndent(res[:3], "", "  ")
    fmt.Println("Example balances:")
    fmt.Println(string(b))
}

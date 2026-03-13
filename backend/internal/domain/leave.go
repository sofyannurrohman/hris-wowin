package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type LeaveType struct {
	ID           uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	CompanyID    *uuid.UUID `gorm:"type:uuid"`
	Name         string     `gorm:"type:varchar(50);not null"`
	IsPaid       bool       `gorm:"default:true"`
	DefaultQuota int        `gorm:"default:12"`
	CreatedAt    time.Time  `gorm:"default:now()"`

	Company *Company `gorm:"foreignKey:CompanyID"`
}

func (lt *LeaveType) BeforeCreate(tx *gorm.DB) (err error) {
	if lt.ID == uuid.Nil {
		lt.ID = uuid.New()
	}
	return
}

type LeaveBalance struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID   uuid.UUID `gorm:"type:uuid;not null"`
	LeaveTypeID  uuid.UUID `gorm:"type:uuid;not null"`
	Year         int       `gorm:"not null"`
	BalanceTotal int       `gorm:"default:0"`
	BalanceUsed  int       `gorm:"default:0"`

	Employee  *Employee  `gorm:"foreignKey:EmployeeID"`
	LeaveType *LeaveType `gorm:"foreignKey:LeaveTypeID"`
}

func (lb *LeaveBalance) BeforeCreate(tx *gorm.DB) (err error) {
	if lb.ID == uuid.Nil {
		lb.ID = uuid.New()
	}
	return
}

type LeaveRequest struct {
	ID            uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID    uuid.UUID  `gorm:"type:uuid;not null"`
	LeaveTypeID   uuid.UUID  `gorm:"type:uuid;not null"`
	StartDate     time.Time  `gorm:"type:date;not null"`
	EndDate       time.Time  `gorm:"type:date;not null"`
	Reason        string     `gorm:"type:text"`
	AttachmentURL string     `gorm:"type:text"`
	Status        string     `gorm:"type:varchar(20);default:'PENDING'"`
	ApprovedBy    *uuid.UUID `gorm:"type:uuid"`
	RejectReason  *string    `gorm:"type:text"`
	CreatedAt     time.Time  `gorm:"default:now()"`

	Employee  *Employee  `gorm:"foreignKey:EmployeeID"`
	LeaveType *LeaveType `gorm:"foreignKey:LeaveTypeID"`
	Approver  *Employee  `gorm:"foreignKey:ApprovedBy"`
}

func (lr *LeaveRequest) BeforeCreate(tx *gorm.DB) (err error) {
	if lr.ID == uuid.Nil {
		lr.ID = uuid.New()
	}
	return
}

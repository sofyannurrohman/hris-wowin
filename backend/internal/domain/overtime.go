package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type OvertimeStatus string

const (
	OvertimePending  OvertimeStatus = "pending"
	OvertimeApproved OvertimeStatus = "approved"
	OvertimeRejected OvertimeStatus = "rejected"
)

type Overtime struct {
	ID              uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID      uuid.UUID      `gorm:"type:uuid;not null;index"`
	Date            time.Time      `gorm:"type:date;not null"`
	StartTime       time.Time      `gorm:"not null"`
	EndTime         time.Time      `gorm:"not null"`
	DurationMinutes int            `gorm:"not null"`
	Reason          string         `gorm:"type:text;not null"`
	Status          OvertimeStatus `gorm:"type:varchar(20);default:'pending'"`
	ApprovedBy      *uuid.UUID     `gorm:"type:uuid"`
	RejectReason    *string        `gorm:"type:text"`
	CreatedAt       time.Time      `gorm:"default:now()"`

	Employee *Employee `gorm:"foreignKey:EmployeeID;constraint:OnDelete:CASCADE;"`
	Approver *Employee `gorm:"foreignKey:ApprovedBy;constraint:OnDelete:CASCADE;"`
}

func (o *Overtime) BeforeCreate(tx *gorm.DB) (err error) {
	if o.ID == uuid.Nil {
		o.ID = uuid.New()
	}
	return
}

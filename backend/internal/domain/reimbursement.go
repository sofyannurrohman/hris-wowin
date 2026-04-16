package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ReimbursementStatus string

const (
	ReimbursementPending  ReimbursementStatus = "PENDING"
	ReimbursementApproved ReimbursementStatus = "APPROVED"
	ReimbursementRejected ReimbursementStatus = "REJECTED"
)

type Reimbursement struct {
	ID             uuid.UUID           `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID     uuid.UUID           `gorm:"type:uuid;not null"`
	Title          string              `gorm:"type:varchar(255);not null"`
	Description    string              `gorm:"type:text"`
	Amount         float64             `gorm:"type:decimal(15,2);not null"`
	AttachmentURL  string              `gorm:"type:text"`
	Status         ReimbursementStatus `gorm:"type:varchar(20);default:'PENDING'"`
	ApprovedBy     *uuid.UUID          `gorm:"type:uuid"`
	RejectedReason *string             `gorm:"type:text"`
	CreatedAt      time.Time           `gorm:"default:now()"`
	UpdatedAt      time.Time           `gorm:"default:now()"`

	Employee *Employee   `gorm:"foreignKey:EmployeeID;constraint:OnDelete:CASCADE;"`
	Approver *Employee   `gorm:"foreignKey:ApprovedBy;constraint:OnDelete:CASCADE;"`
}

func (r *Reimbursement) BeforeCreate(tx *gorm.DB) (err error) {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	return
}

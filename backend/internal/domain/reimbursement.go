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
	ID             uuid.UUID           `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	EmployeeID     uuid.UUID           `gorm:"type:uuid;not null" json:"employee_id"`
	Title          string              `gorm:"type:varchar(255);not null" json:"title"`
	Description    string              `gorm:"type:text" json:"description"`
	Amount         float64             `gorm:"type:decimal(15,2);not null" json:"amount"`
	AttachmentURL  string              `gorm:"type:text" json:"attachment_url"`
	Status         ReimbursementStatus `gorm:"type:varchar(20);default:'PENDING'" json:"status"`
	ApprovedBy     *uuid.UUID          `gorm:"type:uuid" json:"approved_by"`
	RejectedReason *string             `gorm:"type:text" json:"rejected_reason"`
	CreatedAt      time.Time           `gorm:"default:now()" json:"created_at"`
	UpdatedAt      time.Time           `gorm:"default:now()" json:"updated_at"`

	Employee *Employee `gorm:"foreignKey:EmployeeID;constraint:OnDelete:CASCADE;" json:"employee,omitempty"`
	Approver *Employee `gorm:"foreignKey:ApprovedBy;constraint:OnDelete:SET NULL;" json:"approver,omitempty"`
}

func (r *Reimbursement) BeforeCreate(tx *gorm.DB) (err error) {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	return
}

package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SalesPayment struct {
	ID                 uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	SalesTransactionID uuid.UUID `gorm:"type:uuid;not null" json:"sales_transaction_id"`
	EmployeeID         uuid.UUID `gorm:"type:uuid;not null" json:"employee_id"`
	Amount             float64   `gorm:"type:decimal(15,2);not null" json:"amount"`
	PaymentDate        time.Time `gorm:"type:date;not null" json:"payment_date"`
	Notes              string    `gorm:"type:text" json:"notes"`
	CreatedAt          time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt          time.Time `gorm:"default:now()" json:"updated_at"`

	SalesTransaction *SalesTransaction `gorm:"foreignKey:SalesTransactionID" json:"sales_transaction,omitempty"`
	Employee         *Employee         `gorm:"foreignKey:EmployeeID" json:"employee,omitempty"`
}

func (sp *SalesPayment) BeforeCreate(tx *gorm.DB) (err error) {
	if sp.ID == uuid.Nil {
		sp.ID = uuid.New()
	}
	return
}

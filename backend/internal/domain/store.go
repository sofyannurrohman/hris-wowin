package domain

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type Store struct {
	ID                   uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	CompanyID            uuid.UUID  `gorm:"type:uuid;not null" json:"company_id"`
	AssignedEmployeeID   *uuid.UUID `gorm:"type:uuid" json:"assigned_employee_id"` // PENTING: Untuk Rayonisasi
	Name                 string     `gorm:"type:varchar(255);not null" json:"name"`
	OwnerName            string     `gorm:"type:varchar(255)" json:"owner_name"`
	PhoneNumber          string     `gorm:"type:varchar(50)" json:"phone_number"`
	Address              string     `gorm:"type:text" json:"address"`
	Latitude             float64    `gorm:"type:decimal(10,8)" json:"latitude"`
	Longitude            float64    `gorm:"type:decimal(11,8)" json:"longitude"`
	IsActive             bool       `gorm:"default:true" json:"is_active"`
	FirstTransactionDate *time.Time `gorm:"type:date" json:"first_transaction_date"`
	CreatedAt            time.Time  `gorm:"default:now()" json:"created_at"`
	UpdatedAt            time.Time  `gorm:"default:now()" json:"updated_at"`

	VisitDays            pq.Int64Array `gorm:"type:integer[]" json:"visit_days"`
	VisitFrequency       string        `gorm:"type:varchar(10)" json:"visit_frequency"` // F8, F4, F2
	Company          *Company  `gorm:"foreignKey:CompanyID;constraint:OnDelete:CASCADE;" json:"company,omitempty"`
	AssignedEmployee *Employee `gorm:"foreignKey:AssignedEmployeeID;constraint:OnDelete:SET NULL;" json:"assigned_employee,omitempty"`
}

func (s *Store) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}

package domain

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type Store struct {
	ID                   uuid.UUID     `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id" form:"id"`
	CompanyID            uuid.UUID     `gorm:"type:uuid;not null" json:"company_id" form:"company_id"`
	AssignedEmployeeID   *uuid.UUID    `gorm:"type:uuid" json:"assigned_employee_id" form:"assigned_employee_id"` // PENTING: Untuk Rayonisasi
	Name                 string        `gorm:"type:varchar(255);not null" json:"name" form:"name"`
	OwnerName            string        `gorm:"type:varchar(255)" json:"owner_name" form:"owner_name"`
	PhoneNumber          string        `gorm:"type:varchar(50)" json:"phone_number" form:"phone_number"`
	Address              string        `gorm:"type:text" json:"address" form:"address"`
	Latitude             float64       `gorm:"type:decimal(10,8)" json:"latitude" form:"latitude"`
	Longitude            float64       `gorm:"type:decimal(11,8)" json:"longitude" form:"longitude"`
	IsActive             bool          `gorm:"default:true" json:"is_active" form:"is_active"`
	PhotoURL             string        `gorm:"type:text" json:"photo_url" form:"photo_url"`
	FirstTransactionDate *time.Time    `gorm:"type:date" json:"first_transaction_date" form:"first_transaction_date"`
	CreatedAt            time.Time     `gorm:"default:now()" json:"created_at" form:"-"`
	UpdatedAt            time.Time     `gorm:"default:now()" json:"updated_at" form:"-"`

	VisitDays            pq.Int64Array `gorm:"type:integer[]" json:"visit_days" form:"-"`
	VisitFrequency       string        `gorm:"type:varchar(10)" json:"visit_frequency" form:"visit_frequency"` // F8, F4, F2
	Company          *Company  `gorm:"foreignKey:CompanyID;constraint:OnDelete:CASCADE;" json:"company,omitempty"`
	AssignedEmployee *Employee `gorm:"foreignKey:AssignedEmployeeID;constraint:OnDelete:SET NULL;" json:"assigned_employee,omitempty"`
}

func (s *Store) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}

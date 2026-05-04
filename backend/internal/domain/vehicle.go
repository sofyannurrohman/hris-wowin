package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Vehicle struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	CompanyID    uuid.UUID `gorm:"type:uuid;not null" json:"company_id"`
	BranchID     *uuid.UUID `gorm:"type:uuid" json:"branch_id"`
	Name         string    `gorm:"type:varchar(255);not null" json:"name"`
	LicensePlate string    `gorm:"type:varchar(20);uniqueIndex;not null" json:"license_plate"`
	Model        string    `gorm:"type:varchar(100)" json:"model"`
	Type         string    `gorm:"type:varchar(50)" json:"type"` // Truck, Car, Van, Motorcycle
	Status       string    `gorm:"type:varchar(20);default:'AVAILABLE'" json:"status"` // AVAILABLE, IN_USE, MAINTENANCE, BROKEN
	Year         int       `gorm:"type:int" json:"year"`
	Mileage      int       `gorm:"type:int;default:0" json:"mileage"`
	CreatedAt    time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt    time.Time `gorm:"default:now()" json:"updated_at"`

	Company *Company `gorm:"foreignKey:CompanyID" json:"company,omitempty"`
	Branch  *Branch  `gorm:"foreignKey:BranchID" json:"branch,omitempty"`
}

func (v *Vehicle) BeforeCreate(tx *gorm.DB) (err error) {
	if v.ID == uuid.Nil {
		v.ID = uuid.New()
	}
	return
}

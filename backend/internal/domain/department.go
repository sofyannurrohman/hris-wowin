package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Department struct {
	ID        uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	CompanyID *uuid.UUID `gorm:"type:uuid"`
	Name      string     `gorm:"type:varchar(100);not null"`
	ParentID  *uuid.UUID `gorm:"type:uuid"`
	CreatedAt time.Time  `gorm:"default:now()"`

	Company          *Company    `gorm:"foreignKey:CompanyID"`
	ParentDepartment *Department `gorm:"foreignKey:ParentID"`
}

func (d *Department) BeforeCreate(tx *gorm.DB) (err error) {
	if d.ID == uuid.Nil {
		d.ID = uuid.New()
	}
	return
}

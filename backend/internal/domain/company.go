package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Company struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Name      string    `gorm:"type:varchar(255);not null"`
	TaxNumber string    `gorm:"type:varchar(50)"`
	Address   string    `gorm:"type:text"`
	LogoURL   string    `gorm:"type:text"`
	CreatedAt time.Time `gorm:"default:now()"`
	UpdatedAt time.Time `gorm:"default:now()"`
}

func (c *Company) BeforeCreate(tx *gorm.DB) (err error) {
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	return
}

type Branch struct {
	ID          uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	CompanyID   *uuid.UUID `gorm:"type:uuid" json:"company_id"`
	Name        string     `gorm:"type:varchar(100);not null" json:"name"`
	Address     string     `gorm:"type:text" json:"address"`
	Timezone    string     `gorm:"type:varchar(50);default:'Asia/Jakarta'" json:"timezone"`
	Latitude    float64    `gorm:"type:decimal(10,8)" json:"latitude"`
	Longitude   float64    `gorm:"type:decimal(11,8)" json:"longitude"`
	RadiusMeter int        `gorm:"default:100" json:"radius_meter"`
	CreatedAt   time.Time  `gorm:"default:now()" json:"created_at"`
	UpdatedAt   time.Time  `gorm:"default:now()" json:"updated_at"`

	Company *Company `gorm:"foreignKey:CompanyID" json:"company,omitempty"`
}

func (b *Branch) BeforeCreate(tx *gorm.DB) (err error) {
	if b.ID == uuid.Nil {
		b.ID = uuid.New()
	}
	return
}

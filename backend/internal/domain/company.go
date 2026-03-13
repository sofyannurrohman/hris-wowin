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
	ID          uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	CompanyID   *uuid.UUID `gorm:"type:uuid"`
	Name        string     `gorm:"type:varchar(100);not null"`
	Address     string     `gorm:"type:text"`
	Timezone    string     `gorm:"type:varchar(50);default:'Asia/Jakarta'"`
	Latitude    float64    `gorm:"type:decimal(10,8)"`
	Longitude   float64    `gorm:"type:decimal(11,8)"`
	RadiusMeter int        `gorm:"default:100"`
	CreatedAt   time.Time  `gorm:"default:now()"`

	Company *Company `gorm:"foreignKey:CompanyID"`
}

func (b *Branch) BeforeCreate(tx *gorm.DB) (err error) {
	if b.ID == uuid.Nil {
		b.ID = uuid.New()
	}
	return
}

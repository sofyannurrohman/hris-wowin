package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// PayrollConfig represents the global variables used in payroll calculations
// like tax rates thresholds and insurance percentages.
type PayrollConfig struct {
	ID        uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	CompanyID *uuid.UUID `gorm:"type:uuid"`

	// JHT (Jaminan Hari Tua)
	JHTCompanyPercentage  float64 `gorm:"type:decimal(5,2);default:3.70"` // Default 3.7%
	JHTEmployeePercentage float64 `gorm:"type:decimal(5,2);default:2.00"` // Default 2.0%

	// JP (Jaminan Pensiun)
	JPCompanyPercentage  float64 `gorm:"type:decimal(5,2);default:2.00"` // Default 2.0%
	JPEmployeePercentage float64 `gorm:"type:decimal(5,2);default:1.00"` // Default 1.0%
	JPMaxWageBase        float64 `gorm:"type:decimal(15,2);default:10042300"` // Example cap for JP calculation

	// JKK (Kecelakaan Kerja) & JKM (Kematian) usually only company pays
	JKKCompanyPercentage float64 `gorm:"type:decimal(5,2);default:0.24"` // Default 0.24%
	JKMCompanyPercentage float64 `gorm:"type:decimal(5,2);default:0.30"` // Default 0.30%

	// BPJS Kesehatan
	BPJSKesCompanyPercentage  float64 `gorm:"type:decimal(5,2);default:4.00"` // Default 4.0%
	BPJSKesEmployeePercentage float64 `gorm:"type:decimal(5,2);default:1.00"` // Default 1.0%
	BPJSKesMaxWageBase        float64 `gorm:"type:decimal(15,2);default:12000000"` // Cap for BPJS Kes

	// Tax (PPh21 TER)
	PtkpBaseTK0 float64 `gorm:"type:decimal(15,2);default:54000000"` // Dasar PTKP Lajang

	UpdatedAt time.Time `gorm:"default:now()"`
	CreatedAt time.Time `gorm:"default:now()"`

	Company *Company `gorm:"foreignKey:CompanyID"`
}

func (pc *PayrollConfig) BeforeCreate(tx *gorm.DB) (err error) {
	if pc.ID == uuid.Nil {
		pc.ID = uuid.New()
	}
	return
}

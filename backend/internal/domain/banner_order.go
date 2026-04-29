package domain

import (
	"time"

	"github.com/google/uuid"
)

type BannerOrder struct {
	ID         uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	CompanyID  uuid.UUID `gorm:"type:uuid;not null" json:"company_id"`
	EmployeeID uuid.UUID `gorm:"type:uuid;not null" json:"employee_id"`
	StoreName  string    `gorm:"type:varchar(255);not null" json:"store_name"`
	Size       float64   `gorm:"type:decimal(10,2);not null" json:"size"`
	Notes      *string   `gorm:"type:text" json:"notes"`
	Status     string    `gorm:"type:varchar(50);default:'PENDING'" json:"status"`
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt  time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

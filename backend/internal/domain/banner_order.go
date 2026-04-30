package domain

import (
	"time"

	"github.com/google/uuid"
)

type BannerOrder struct {
	ID         uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	CompanyID  uuid.UUID `gorm:"type:uuid;not null" json:"company_id"`
	EmployeeID uuid.UUID `gorm:"type:uuid;not null" json:"employee_id"`
	StoreID    *uuid.UUID `gorm:"type:uuid" json:"store_id"`
	CampaignName string  `gorm:"type:varchar(255)" json:"campaign_name"`
	StoreName  string    `gorm:"type:varchar(255)" json:"store_name"`
	Location   string    `gorm:"type:varchar(255)" json:"location"`
	BannerType string    `gorm:"type:varchar(100)" json:"banner_type"`
	Size       float64   `gorm:"type:decimal(10,2);not null" json:"size"`
	DesignURL  string    `gorm:"type:text" json:"design_url"`
	DocumentationImageURL string `gorm:"type:text" json:"documentation_image_url"`
	Notes      *string   `gorm:"type:text" json:"notes"`
	Status     string    `gorm:"type:varchar(50);default:'PENDING'" json:"status"`
	DesignerID *uuid.UUID `gorm:"type:uuid" json:"designer_id"`
	InstallerID *uuid.UUID `gorm:"type:uuid" json:"installer_id"`
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt  time.Time `gorm:"autoUpdateTime" json:"updated_at"`

	Employee *Employee `gorm:"foreignKey:EmployeeID;constraint:OnDelete:SET NULL;" json:"employee,omitempty"`
	Designer *Employee `gorm:"foreignKey:DesignerID;constraint:OnDelete:SET NULL;" json:"designer,omitempty"`
	Installer *Employee `gorm:"foreignKey:InstallerID;constraint:OnDelete:SET NULL;" json:"installer,omitempty"`
}

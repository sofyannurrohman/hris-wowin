package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SalesTransaction struct {
	ID              uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	VisitID         *uuid.UUID `gorm:"type:uuid" json:"visit_id"` // Mengikat transaksi ke log check-in
	CompanyID       uuid.UUID  `gorm:"type:uuid;not null" json:"company_id"`
	StoreID         uuid.UUID  `gorm:"type:uuid;not null" json:"store_id"`
	EmployeeID      uuid.UUID  `gorm:"type:uuid;not null" json:"employee_id"`
	ReceiptNo       string     `gorm:"type:varchar(100)" json:"receipt_no"`
	ReceiptImageURL string     `gorm:"type:text" json:"receipt_image_url"`
	TotalAmount     float64    `gorm:"type:decimal(15,2);not null" json:"total_amount"`
	StoreCategory   string     `gorm:"type:varchar(50)" json:"store_category"` // 'TOKO_LAMA', 'TOKO_BARU'
	PeriodMonth     int        `gorm:"type:int;not null" json:"period_month"`
	PeriodYear      int        `gorm:"type:int;not null" json:"period_year"`
	TransactionDate time.Time  `gorm:"type:date;not null" json:"transaction_date"`
	Status          string     `gorm:"type:varchar(50);default:'PENDING'" json:"status"` // 'PENDING', 'VERIFIED'
	CreatedAt       time.Time  `gorm:"default:now()" json:"created_at"`
	UpdatedAt       time.Time  `gorm:"default:now()" json:"updated_at"`

	Company  *Company  `gorm:"foreignKey:CompanyID;constraint:OnDelete:CASCADE;" json:"company,omitempty"`
	Store    *Store    `gorm:"foreignKey:StoreID;constraint:OnDelete:CASCADE;" json:"store,omitempty"`
	Employee *Employee `gorm:"foreignKey:EmployeeID;constraint:OnDelete:CASCADE;" json:"employee,omitempty"`
}

func (st *SalesTransaction) BeforeCreate(tx *gorm.DB) (err error) {
	if st.ID == uuid.Nil {
		st.ID = uuid.New()
	}
	return
}

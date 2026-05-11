package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SalesStock struct {
	ID         uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	EmployeeID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_employee_product" json:"employee_id"`
	ProductID  uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_employee_product" json:"product_id"`
	Quantity   int       `gorm:"type:int;default:0" json:"quantity"`
	UpdatedAt  time.Time `gorm:"default:now()" json:"updated_at"`

	Employee *Employee `gorm:"foreignKey:EmployeeID" json:"employee,omitempty"`
	Product  *Product  `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type SalesTransferType string

const (
	SalesTransferOut SalesTransferType = "TRANSFER" // Warehouse -> Salesman
	SalesTransferIn  SalesTransferType = "RETURN"   // Salesman -> Warehouse
)

type SalesTransferStatus string

const (
	SalesTransferPending   SalesTransferStatus = "PENDING"
	SalesTransferCompleted SalesTransferStatus = "COMPLETED"
	SalesTransferCancelled SalesTransferStatus = "CANCELLED"
)

type SalesTransfer struct {
	ID            uuid.UUID           `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	BranchID      uuid.UUID           `gorm:"type:uuid;not null" json:"branch_id"`
	EmployeeID    uuid.UUID           `gorm:"type:uuid;not null" json:"employee_id"`
	ProductID     uuid.UUID           `gorm:"type:uuid;not null" json:"product_id"`
	Quantity      int                 `gorm:"type:int;not null" json:"quantity"`
	Unit          string              `gorm:"type:varchar(20);default:'pcs'" json:"unit"`
	Type          SalesTransferType   `gorm:"type:varchar(20);not null" json:"type"`
	Status        SalesTransferStatus `gorm:"type:varchar(20);default:'PENDING'" json:"status"`
	ReferenceNo   string              `gorm:"type:varchar(50)" json:"reference_no"`
	Notes         string              `gorm:"type:text" json:"notes"`
	TransferDate  time.Time           `gorm:"default:now()" json:"transfer_date"`
	CreatedAt     time.Time           `gorm:"default:now()" json:"created_at"`
	UpdatedAt     time.Time           `gorm:"default:now()" json:"updated_at"`

	Branch   *Branch   `gorm:"foreignKey:BranchID" json:"branch,omitempty"`
	Employee *Employee `gorm:"foreignKey:EmployeeID" json:"employee,omitempty"`
	Product  *Product  `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

func (s *SalesStock) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}

func (s *SalesTransfer) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}

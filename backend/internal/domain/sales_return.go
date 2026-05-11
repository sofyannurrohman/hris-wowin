package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SalesReturnStatus string

const (
	ReturnStatusPending  SalesReturnStatus = "PENDING"
	ReturnStatusApproved SalesReturnStatus = "APPROVED"
	ReturnStatusRejected SalesReturnStatus = "REJECTED"
)

// SalesReturn mencatat pengembalian barang dari pelanggan.
type SalesReturn struct {
	ID            uuid.UUID         `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	ReturnNo      string            `gorm:"type:varchar(50);unique;not null" json:"return_no"`
	SalesOrderID  uuid.UUID         `gorm:"type:uuid;not null" json:"sales_order_id"`
	TransactionID *uuid.UUID        `gorm:"type:uuid" json:"transaction_id"` // Link ke Invoice
	BranchID      uuid.UUID         `gorm:"type:uuid;not null" json:"branch_id"`
	EmployeeID    uuid.UUID         `gorm:"type:uuid;not null" json:"employee_id"` // Yang menginput (salesman/driver)
	Status        SalesReturnStatus `gorm:"type:varchar(20);default:'PENDING'" json:"status"`
	TotalAmount   float64           `gorm:"type:decimal(15,2);default:0" json:"total_amount"` // Nilai yang memotong tagihan
	Notes         string            `gorm:"type:text" json:"notes"`

	ApprovedAt   *time.Time `json:"approved_at,omitempty"`
	ApprovedByID *uuid.UUID `gorm:"type:uuid" json:"approved_by_id"`

	CreatedAt time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt time.Time `gorm:"default:now()" json:"updated_at"`

	SalesOrder  *SalesOrder       `gorm:"foreignKey:SalesOrderID" json:"sales_order,omitempty"`
	Transaction *SalesTransaction `gorm:"foreignKey:TransactionID" json:"transaction,omitempty"`
	Employee    *Employee         `gorm:"foreignKey:EmployeeID" json:"employee,omitempty"`
	Items       []SalesReturnItem `gorm:"foreignKey:SalesReturnID" json:"items,omitempty"`
}

// SalesReturnItem mencatat produk yang diretur.
type SalesReturnItem struct {
	ID            uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	SalesReturnID uuid.UUID `gorm:"type:uuid;not null" json:"sales_return_id"`
	ProductID     uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
	Quantity      int       `gorm:"type:int;not null" json:"quantity"`
	Price         float64   `gorm:"type:decimal(15,2);default:0" json:"price"`
	Reason        string    `gorm:"type:varchar(255)" json:"reason"`
	Condition     string    `gorm:"type:varchar(20);default:'DAMAGED'" json:"condition"` // 'GOOD', 'DAMAGED'

	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

func (sr *SalesReturn) BeforeCreate(tx *gorm.DB) (err error) {
	if sr.ID == uuid.Nil {
		sr.ID = uuid.New()
	}
	return
}

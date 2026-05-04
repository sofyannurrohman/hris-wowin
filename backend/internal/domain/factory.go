package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Factory struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	CompanyID uuid.UUID `gorm:"type:uuid;not null" json:"company_id"`
	BranchID  uuid.UUID `gorm:"type:uuid;not null" json:"branch_id"`
	Name      string    `gorm:"type:varchar(255);not null" json:"name"`
	Location  string    `gorm:"type:text" json:"location"`
	CreatedAt time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt time.Time `gorm:"default:now()" json:"updated_at"`

	Branch  *Branch  `gorm:"foreignKey:BranchID" json:"branch,omitempty"`
	Company *Company `gorm:"foreignKey:CompanyID" json:"company,omitempty"`
}

type Product struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	CompanyID   uuid.UUID `gorm:"type:uuid;not null" json:"company_id"`
	Name        string    `gorm:"type:varchar(255);not null" json:"name"`
	SKU         string    `gorm:"type:varchar(50);uniqueIndex;not null" json:"sku"`
	Unit        string    `gorm:"type:varchar(20);not null" json:"unit"` // e.g., PCS, BOX, KG
	Weight       float64   `gorm:"type:decimal(10,2);default:0" json:"weight"` // Weight per unit in KG
	CostPrice    float64   `gorm:"type:decimal(15,2);default:0" json:"cost_price"` // HPP (Harga Pokok Penjualan)
	SellingPrice float64   `gorm:"type:decimal(15,2);default:0" json:"selling_price"` // Harga Jual
	Description  string    `gorm:"type:text" json:"description"`
	CreatedAt    time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt    time.Time `gorm:"default:now()" json:"updated_at"`
}

type FactoryStock struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FactoryID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_factory_product" json:"factory_id"`
	ProductID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_factory_product" json:"product_id"`
	Quantity  int       `gorm:"type:int;default:0" json:"quantity"`
	UpdatedAt time.Time `gorm:"default:now()" json:"updated_at"`

	Factory *Factory `gorm:"foreignKey:FactoryID" json:"factory,omitempty"`
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type ProductionLog struct {
	ID             uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FactoryID      uuid.UUID `gorm:"type:uuid;not null" json:"factory_id"`
	ProductID      uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
	EmployeeID     uuid.UUID `gorm:"type:uuid;not null" json:"employee_id"`
	Quantity       int       `gorm:"type:int;not null" json:"quantity"`
	ProductionDate time.Time `gorm:"type:timestamptz;default:now()" json:"production_date"`
	Notes          string    `gorm:"type:text" json:"notes"`
	CreatedAt      time.Time `gorm:"default:now()" json:"created_at"`

	Factory  *Factory  `gorm:"foreignKey:FactoryID" json:"factory,omitempty"`
	Product  *Product  `gorm:"foreignKey:ProductID" json:"product,omitempty"`
	Employee *Employee `gorm:"foreignKey:EmployeeID" json:"employee,omitempty"`
}

type ProductTransfer struct {
	ID            uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FromFactoryID uuid.UUID `gorm:"type:uuid;not null" json:"from_factory_id"`
	ToBranchID    uuid.UUID `gorm:"type:uuid;not null" json:"to_branch_id"`
	ProductID     uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
	Quantity      int       `gorm:"type:int;not null" json:"quantity"`
	TotalWeight   float64   `gorm:"type:decimal(10,2)" json:"total_weight"`
	Status          string    `gorm:"type:varchar(20);default:'REQUESTED'" json:"status"` // REQUESTED, APPROVED, SHIPPED, RECEIVED, REJECTED
	DeliveryOrderNo string    `gorm:"type:varchar(100);uniqueIndex" json:"delivery_order_no"`
	Notes           string    `gorm:"type:text" json:"notes"`
	ShippedAt       *time.Time `json:"shipped_at,omitempty"`
	ReceivedAt      *time.Time `json:"received_at,omitempty"`
	CreatedAt       time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt       time.Time `gorm:"default:now()" json:"updated_at"`

	FromFactory *Factory `gorm:"foreignKey:FromFactoryID" json:"from_factory,omitempty"`
	ToBranch    *Branch  `gorm:"foreignKey:ToBranchID" json:"to_branch,omitempty"`
	Product     *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type WarehouseStock struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	BranchID  uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_branch_product" json:"branch_id"`
	ProductID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_branch_product" json:"product_id"`
	Quantity  int       `gorm:"type:int;default:0" json:"quantity"`
	MinLimit  int       `gorm:"type:int;default:0" json:"min_limit"`
	UpdatedAt time.Time `gorm:"default:now()" json:"updated_at"`

	Branch  *Branch  `gorm:"foreignKey:BranchID" json:"branch,omitempty"`
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type WarehouseLog struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	BranchID  uuid.UUID `gorm:"type:uuid;not null" json:"branch_id"`
	ProductID uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
	Type      string    `gorm:"type:varchar(20);not null" json:"type"` // IN, OUT
	Source    string    `gorm:"type:varchar(50)" json:"source"`       // FACTORY_TRANSFER, SALES, OPNAME
	Quantity  int       `gorm:"type:int;not null" json:"quantity"`
	CreatedAt time.Time `gorm:"default:now()" json:"created_at"`

	Branch  *Branch  `gorm:"foreignKey:BranchID" json:"branch,omitempty"`
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type FactoryInventoryLog struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FactoryID uuid.UUID `gorm:"type:uuid;not null" json:"factory_id"`
	ProductID uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
	Type      string    `gorm:"type:varchar(20);not null" json:"type"` // IN, OUT
	Source    string    `gorm:"type:varchar(50)" json:"source"`       // PRODUCTION, TRANSFER, ADJUSTMENT
	Quantity  int       `gorm:"type:int;not null" json:"quantity"`
	CreatedAt time.Time `gorm:"default:now()" json:"created_at"`

	Factory *Factory `gorm:"foreignKey:FactoryID" json:"factory,omitempty"`
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

func (f *Factory) BeforeCreate(tx *gorm.DB) (err error) {
	if f.ID == uuid.Nil {
		f.ID = uuid.New()
	}
	return
}

func (p *Product) BeforeCreate(tx *gorm.DB) (err error) {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return
}

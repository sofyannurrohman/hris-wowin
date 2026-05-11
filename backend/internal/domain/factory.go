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
	ID          uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id" form:"id"`
	CompanyID   uuid.UUID `gorm:"type:uuid;not null" json:"company_id" form:"company_id"`
	Name        string    `gorm:"type:varchar(255);not null" json:"name" form:"name"`
	SKU         string    `gorm:"type:varchar(50);uniqueIndex;not null" json:"sku" form:"sku"`
	Unit        string    `gorm:"type:varchar(20);not null" json:"unit" form:"unit"` // e.g., PCS, BOX, KG
	Category     string    `gorm:"type:varchar(100)" json:"category" form:"category"`
	Brand        string    `gorm:"type:varchar(100)" json:"brand" form:"brand"`
	Weight       float64   `gorm:"type:decimal(10,2);default:0" json:"weight" form:"weight"`
	WeightUnit   string    `gorm:"type:varchar(10);default:'KG'" json:"weight_unit" form:"weight_unit"` // GR, KG, TON
	CostPrice    float64   `gorm:"type:decimal(15,2);default:0" json:"cost_price" form:"cost_price"` // HPP (Harga Pokok Penjualan)
	SellingPrice float64   `gorm:"type:decimal(15,2);default:0" json:"selling_price" form:"selling_price"` // Harga Jual
	Description  string    `gorm:"type:text" json:"description" form:"description"`
	Specs        string    `gorm:"type:text" json:"specs" form:"specs"` // Detailed technical specs
	ImageURL     string    `gorm:"type:text" json:"image_url" form:"image_url"`
	CreatedAt    time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt    time.Time `gorm:"default:now()" json:"updated_at"`
}

type FactoryStock struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FactoryID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_factory_product_batch" json:"factory_id"`
	ProductID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_factory_product_batch" json:"product_id"`
	BatchNo   string    `gorm:"type:varchar(50);not null;default:'DEFAULT';uniqueIndex:idx_factory_product_batch" json:"batch_no"`
	ExpiryDate *time.Time `json:"expiry_date"`
	Quantity  int       `gorm:"type:int;default:0" json:"quantity"`
	CreatedAt time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt time.Time `gorm:"default:now()" json:"updated_at"`

	Factory *Factory `gorm:"foreignKey:FactoryID" json:"factory,omitempty"`
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type ProductionLog struct {
	ID             uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FactoryID      uuid.UUID `gorm:"type:uuid;not null" json:"factory_id"`
	ProductID      uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
	BatchNo        string    `gorm:"type:varchar(50);not null" json:"batch_no"`
	ExpiryDate     *time.Time `json:"expiry_date"`
	EmployeeID     uuid.UUID `gorm:"type:uuid;not null" json:"employee_id"`
	Quantity       int       `gorm:"type:int;not null" json:"quantity"`
	CartonCount    int       `gorm:"type:int" json:"carton_count"`
	PiecesPerCarton int      `gorm:"type:int" json:"pieces_per_carton"`
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
	BatchNo       string    `gorm:"type:varchar(50);not null;default:'DEFAULT'" json:"batch_no"`
	ExpiryDate    *time.Time `json:"expiry_date"`
	Quantity      int       `gorm:"type:int;not null" json:"quantity"`
	TotalWeight   float64   `gorm:"type:decimal(10,2)" json:"total_weight"`
	Status          string    `gorm:"type:varchar(20);default:'REQUESTED'" json:"status"` // REQUESTED, APPROVED, SHIPPED, RECEIVED, REJECTED
	DeliveryOrderNo string    `gorm:"type:varchar(100);uniqueIndex" json:"delivery_order_no"`
	Notes           string    `gorm:"type:text" json:"notes"`
	ShippedAt       *time.Time `json:"shipped_at,omitempty"`
	ReceivedAt      *time.Time `json:"received_at,omitempty"`
	EstimatedArrival *time.Time `json:"estimated_arrival,omitempty"`
	TargetShipmentDate *time.Time `json:"target_shipment_date,omitempty"`
	InitiatedBy      string    `gorm:"type:varchar(20);default:'FACTORY'" json:"initiated_by"`
	CreatedAt       time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt       time.Time `gorm:"default:now()" json:"updated_at"`

	FromFactory *Factory `gorm:"foreignKey:FromFactoryID" json:"from_factory,omitempty"`
	ToBranch    *Branch  `gorm:"foreignKey:ToBranchID" json:"to_branch,omitempty"`
	Product     *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type ProductTransferItem struct {
	ProductID uuid.UUID `json:"product_id"`
	Quantity  int       `json:"quantity"`
}

type WarehouseStock struct {
	ID               uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	BranchID         uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_branch_product_type_batch" json:"branch_id"`
	ProductID        uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_branch_product_type_batch" json:"product_id"`
	StockType        string    `gorm:"type:varchar(20);default:'GOOD';uniqueIndex:idx_branch_product_type_batch" json:"stock_type"` // 'GOOD', 'QUARANTINE'
	BatchNo          string    `gorm:"type:varchar(50);not null;default:'DEFAULT';uniqueIndex:idx_branch_product_type_batch" json:"batch_no"`
	ExpiryDate       *time.Time `json:"expiry_date"`
	Quantity         int       `gorm:"type:int;default:0" json:"quantity"`
	ReservedQuantity int       `gorm:"type:int;default:0" json:"reserved_quantity"` // Stok ter-reserve oleh SO CONFIRMED
	MinLimit         int       `gorm:"type:int;default:0" json:"min_limit"`
	CreatedAt        time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt        time.Time `gorm:"default:now()" json:"updated_at"`

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
	BatchNo   string    `gorm:"type:varchar(50)" json:"batch_no"`
	Quantity  int       `gorm:"type:int;not null" json:"quantity"`
	CreatedAt time.Time `gorm:"default:now()" json:"created_at"`

	Factory *Factory `gorm:"foreignKey:FactoryID" json:"factory,omitempty"`
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// ProductionRecipe mendefinisikan resep/BOM untuk sebuah produk jadi.
type ProductionRecipe struct {
	ID              uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FinishedProductID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex" json:"finished_product_id"`
	Description      string    `gorm:"type:text" json:"description"`
	CreatedAt       time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt       time.Time `gorm:"default:now()" json:"updated_at"`

	FinishedProduct *Product               `gorm:"foreignKey:FinishedProductID" json:"finished_product,omitempty"`
	Items           []ProductionRecipeItem `gorm:"foreignKey:RecipeID" json:"items,omitempty"`
}

// ProductionRecipeItem mendefinisikan bahan baku yang dibutuhkan dalam resep.
type ProductionRecipeItem struct {
	ID            uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	RecipeID      uuid.UUID `gorm:"type:uuid;not null" json:"recipe_id"`
	RawProductID  uuid.UUID `gorm:"type:uuid;not null" json:"raw_product_id"`
	Quantity      float64   `gorm:"type:decimal(10,4);not null" json:"quantity"` // Jumlah bahan per 1 unit barang jadi

	RawProduct *Product `gorm:"foreignKey:RawProductID" json:"raw_product,omitempty"`
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


package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type DeliveryBatchStatus string

const (
	DeliveryBatchWaitingApproval    DeliveryBatchStatus = "WAITING_APPROVAL"    // Menunggu persetujuan Supervisor
	DeliveryBatchSupervisorApproved DeliveryBatchStatus = "SUPERVISOR_APPROVED" // Disetujui Supervisor, SJ terbit
	DeliveryBatchPicking            DeliveryBatchStatus = "PICKING"             // Driver sedang ambil barang di Gudang
	DeliveryBatchOnDelivery         DeliveryBatchStatus = "ON_DELIVERY"         // Barang sedang dikirim ke Customer
	DeliveryBatchCompleted          DeliveryBatchStatus = "COMPLETED"           // Semua nota sudah selesai

	// Legacy statuses
	DeliveryBatchWaitingAssignment DeliveryBatchStatus = "WAITING_ASSIGNMENT"
	DeliveryBatchPending           DeliveryBatchStatus = "PENDING"
)

type DeliveryBatch struct {
	ID              uuid.UUID           `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	CompanyID       uuid.UUID           `gorm:"type:uuid;not null" json:"company_id"`
	BranchID        *uuid.UUID          `gorm:"type:uuid" json:"branch_id"`
	DriverID        *uuid.UUID          `gorm:"type:uuid" json:"driver_id"`
	VehicleID       *uuid.UUID          `gorm:"type:uuid" json:"vehicle_id"`
	DeliveryOrderNo *string             `gorm:"type:varchar(100);uniqueIndex" json:"delivery_order_no"`
	Status          DeliveryBatchStatus `gorm:"type:varchar(30);default:'WAITING_APPROVAL'" json:"status"`
	Notes           string              `gorm:"type:text" json:"notes"`

	// QR Code / Barcode untuk Surat Jalan digital
	BarcodeData string `gorm:"type:varchar(255)" json:"barcode_data"`

	// Approval & Assignment
	AdminNotaID  *uuid.UUID `gorm:"type:uuid" json:"admin_nota_id"`
	SupervisorID *uuid.UUID `gorm:"type:uuid" json:"supervisor_id"`
	ApprovedAt   *time.Time `json:"approved_at,omitempty"`
	AssignedAt   *time.Time `json:"assigned_at,omitempty"`

	// Timeline
	PickingStartedAt *time.Time `json:"picking_started_at,omitempty"` // Driver tiba di Gudang
	StartedAt        *time.Time `json:"started_at,omitempty"`        // Driver mulai kirim
	FinishedAt       *time.Time `json:"finished_at,omitempty"`       // Semua nota selesai

	// Rekonsiliasi Cash
	TotalCashCollected float64 `gorm:"type:decimal(15,2);default:0" json:"total_cash_collected"`
	CashSettledAt      *time.Time `json:"cash_settled_at,omitempty"`

	CreatedAt time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt time.Time `gorm:"default:now()" json:"updated_at"`

	Driver      *Employee      `gorm:"foreignKey:DriverID" json:"driver,omitempty"`
	Vehicle     *Vehicle       `gorm:"foreignKey:VehicleID" json:"vehicle,omitempty"`
	AdminNota   *Employee      `gorm:"foreignKey:AdminNotaID" json:"admin_nota,omitempty"`
	Supervisor  *Employee      `gorm:"foreignKey:SupervisorID" json:"supervisor,omitempty"`
	Items       []DeliveryItem `gorm:"foreignKey:DeliveryBatchID" json:"items,omitempty"`
}

type DeliveryItemStatus string

const (
	DeliveryItemPending   DeliveryItemStatus = "PENDING"
	DeliveryItemDelivered DeliveryItemStatus = "DELIVERED"
	DeliveryItemFailed    DeliveryItemStatus = "FAILED"
)

// DeliveryItem sekarang merujuk ke SalesOrder, bukan SalesTransaction.
// Invoice (SalesTransaction) baru dibuat SETELAH barang diterima customer dan pembayaran ditagih.
type DeliveryItem struct {
	ID              uuid.UUID          `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	DeliveryBatchID uuid.UUID          `gorm:"type:uuid;not null" json:"delivery_batch_id"`
	SalesOrderID    uuid.UUID          `gorm:"type:uuid;not null" json:"sales_order_id"`
	Sequence        int                `gorm:"type:int;not null" json:"sequence"`
	Status          DeliveryItemStatus `gorm:"type:varchar(20);default:'PENDING'" json:"status"`
	Notes           string             `gorm:"type:text" json:"notes"`

	// Barcode per nota (bisa di-scan driver saat serahkan ke customer)
	BarcodeData string `gorm:"type:varchar(255)" json:"barcode_data"`

	// Konfirmasi pengiriman
	DeliveredAt *time.Time `json:"delivered_at,omitempty"`
	ReceivedBy  string     `gorm:"type:varchar(100)" json:"received_by"`
	PODImageURL string     `gorm:"type:text" json:"pod_image_url"`

	// Penagihan pembayaran oleh Driver
	PaymentCollected       bool       `gorm:"default:false" json:"payment_collected"`
	PaymentAmount          float64    `gorm:"type:decimal(15,2);default:0" json:"payment_amount"`
	PaymentMethod          string     `gorm:"type:varchar(50)" json:"payment_method"`
	PaymentCollectedAt     *time.Time `json:"payment_collected_at,omitempty"`

	// Legacy field — dijaga agar tidak break kode yang sudah ada
	SalesTransactionID *uuid.UUID `gorm:"type:uuid" json:"sales_transaction_id"`

	SalesOrder      *SalesOrder      `gorm:"foreignKey:SalesOrderID" json:"sales_order,omitempty"`
	SalesTransaction *SalesTransaction `gorm:"foreignKey:SalesTransactionID" json:"sales_transaction,omitempty"`
	DeliveryBatch   *DeliveryBatch   `gorm:"foreignKey:DeliveryBatchID" json:"delivery_batch,omitempty"`
}

func (db *DeliveryBatch) BeforeCreate(tx *gorm.DB) (err error) {
	if db.ID == uuid.Nil {
		db.ID = uuid.New()
	}
	return
}

func (di *DeliveryItem) BeforeCreate(tx *gorm.DB) (err error) {
	if di.ID == uuid.Nil {
		di.ID = uuid.New()
	}
	return
}

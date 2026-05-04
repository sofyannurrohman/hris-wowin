package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type DeliveryBatchStatus string

const (
	DeliveryBatchPending    DeliveryBatchStatus = "PENDING"
	DeliveryBatchOnDelivery DeliveryBatchStatus = "ON_DELIVERY"
	DeliveryBatchCompleted  DeliveryBatchStatus = "COMPLETED"
)

type DeliveryBatch struct {
	ID              uuid.UUID           `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	CompanyID       uuid.UUID           `gorm:"type:uuid;not null" json:"company_id"`
	DriverID        uuid.UUID           `gorm:"type:uuid;not null" json:"driver_id"`
	VehicleID       uuid.UUID           `gorm:"type:uuid;not null" json:"vehicle_id"`
	DeliveryOrderNo string              `gorm:"type:varchar(100);uniqueIndex" json:"delivery_order_no"`
	Status          DeliveryBatchStatus `gorm:"type:varchar(20);default:'PENDING'" json:"status"`
	StartedAt       *time.Time          `json:"started_at,omitempty"`
	FinishedAt      *time.Time          `json:"finished_at,omitempty"`
	CreatedAt       time.Time           `gorm:"default:now()" json:"created_at"`
	UpdatedAt       time.Time           `gorm:"default:now()" json:"updated_at"`

	Driver  *Employee       `gorm:"foreignKey:DriverID" json:"driver,omitempty"`
	Vehicle *Vehicle        `gorm:"foreignKey:VehicleID" json:"vehicle,omitempty"`
	Items   []DeliveryItem  `gorm:"foreignKey:DeliveryBatchID" json:"items,omitempty"`
}

type DeliveryItemStatus string

const (
	DeliveryItemPending   DeliveryItemStatus = "PENDING"
	DeliveryItemDelivered DeliveryItemStatus = "DELIVERED"
	DeliveryItemFailed    DeliveryItemStatus = "FAILED"
)

type DeliveryItem struct {
	ID                 uuid.UUID          `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	DeliveryBatchID    uuid.UUID          `gorm:"type:uuid;not null" json:"delivery_batch_id"`
	SalesTransactionID uuid.UUID          `gorm:"type:uuid;not null" json:"sales_transaction_id"`
	Sequence           int                `gorm:"type:int;not null" json:"sequence"`
	Status             DeliveryItemStatus `gorm:"type:varchar(20);default:'PENDING'" json:"status"`
	Notes              string             `gorm:"type:text" json:"notes"`
	DeliveredAt        *time.Time         `json:"delivered_at,omitempty"`

	SalesTransaction *SalesTransaction `gorm:"foreignKey:SalesTransactionID" json:"sales_transaction,omitempty"`
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

package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type DeliveryRepository interface {
	CreateBatch(batch *domain.DeliveryBatch) error
	GetBatchByDO(doNo string) (*domain.DeliveryBatch, error)
	GetBatchByID(id uuid.UUID) (*domain.DeliveryBatch, error)
	UpdateBatch(batch *domain.DeliveryBatch) error
	UpdateItem(item *domain.DeliveryItem) error
	GetBatchesByDriver(driverID uuid.UUID) ([]domain.DeliveryBatch, error)
	ListBatches() ([]domain.DeliveryBatch, error)
	GetItemByReceiptNo(receiptNo string) (*domain.DeliveryItem, error)
	DeleteBatch(id uuid.UUID) error
}

type deliveryRepository struct {
	db *gorm.DB
}

func NewDeliveryRepository(db *gorm.DB) DeliveryRepository {
	return &deliveryRepository{db}
}

func (r *deliveryRepository) CreateBatch(batch *domain.DeliveryBatch) error {
	return r.db.Create(batch).Error
}

func (r *deliveryRepository) GetBatchByDO(doNo string) (*domain.DeliveryBatch, error) {
	var batch domain.DeliveryBatch
	err := r.db.Preload("Driver").Preload("Vehicle").
		Preload("AdminNota").Preload("Supervisor").
		Preload("Items.SalesTransaction.Store").
		Preload("Items.SalesTransaction.Employee").
		Preload("Items.SalesTransaction.Items.Product").
		Where("delivery_order_no = ?", doNo).First(&batch).Error
	return &batch, err
}

func (r *deliveryRepository) GetBatchByID(id uuid.UUID) (*domain.DeliveryBatch, error) {
	var batch domain.DeliveryBatch
	err := r.db.Preload("Driver").Preload("Vehicle").
		Preload("AdminNota").Preload("Supervisor").
		Preload("Items.SalesTransaction.Store").
		Preload("Items.SalesTransaction.Employee").
		Preload("Items.SalesTransaction.Items.Product").
		First(&batch, id).Error
	return &batch, err
}

func (r *deliveryRepository) UpdateBatch(batch *domain.DeliveryBatch) error {
	// Clear existing items and replace with new ones to avoid orphans
	if err := r.db.Model(batch).Association("Items").Replace(batch.Items); err != nil {
		return err
	}
	// Save the rest of the fields
	return r.db.Session(&gorm.Session{FullSaveAssociations: false}).Save(batch).Error
}

func (r *deliveryRepository) UpdateItem(item *domain.DeliveryItem) error {
	return r.db.Save(item).Error
}

func (r *deliveryRepository) GetBatchesByDriver(driverID uuid.UUID) ([]domain.DeliveryBatch, error) {
	var batches []domain.DeliveryBatch
	err := r.db.Preload("Items.SalesTransaction.Store").
		Where("driver_id = ? AND status != ?", driverID, domain.DeliveryBatchCompleted).
		Order("created_at DESC").Find(&batches).Error
	return batches, err
}

func (r *deliveryRepository) ListBatches() ([]domain.DeliveryBatch, error) {
	var batches []domain.DeliveryBatch
	err := r.db.Preload("Driver").Preload("Vehicle").
		Preload("Items.SalesTransaction.Store").
		Order("created_at DESC").Find(&batches).Error
	return batches, err
}

func (r *deliveryRepository) GetItemByReceiptNo(receiptNo string) (*domain.DeliveryItem, error) {
	var item domain.DeliveryItem
	err := r.db.Preload("SalesTransaction").
		Joins("JOIN sales_transactions ON sales_transactions.id = delivery_items.sales_transaction_id").
		Where("sales_transactions.receipt_no = ?", receiptNo).
		First(&item).Error
	return &item, err
}

func (r *deliveryRepository) DeleteBatch(id uuid.UUID) error {
	return r.db.Delete(&domain.DeliveryBatch{}, id).Error
}

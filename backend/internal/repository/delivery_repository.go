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
		Preload("Items.SalesTransaction.Store").
		Where("delivery_order_no = ?", doNo).First(&batch).Error
	return &batch, err
}

func (r *deliveryRepository) GetBatchByID(id uuid.UUID) (*domain.DeliveryBatch, error) {
	var batch domain.DeliveryBatch
	err := r.db.Preload("Driver").Preload("Vehicle").
		Preload("Items.SalesTransaction.Store").
		First(&batch, id).Error
	return &batch, err
}

func (r *deliveryRepository) UpdateBatch(batch *domain.DeliveryBatch) error {
	return r.db.Save(batch).Error
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

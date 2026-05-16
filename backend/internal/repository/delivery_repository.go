package repository

import (
	"time"

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
	GetBatchesHistoryByDriver(driverID uuid.UUID) ([]domain.DeliveryBatch, error)
	ListBatches() ([]domain.DeliveryBatch, error)
	GetItemByReceiptNo(receiptNo string) (*domain.DeliveryItem, error)
	GetItemBySONumber(soNumber string) (*domain.DeliveryItem, error)
	DeleteBatch(id uuid.UUID) error
}

type deliveryRepository struct {
	db *gorm.DB
}

func NewDeliveryRepository(db *gorm.DB) DeliveryRepository {
	return &deliveryRepository{db}
}

// preloadBatch adalah helper untuk memuat semua relasi yang dibutuhkan secara konsisten.
func (r *deliveryRepository) preloadBatch(db *gorm.DB) *gorm.DB {
	return db.
		Preload("Driver").
		Preload("Vehicle").
		Preload("AdminNota").
		Preload("Supervisor").
		// Alur baru: muat SalesOrder beserta relasinya
		Preload("Items.SalesOrder").
		Preload("Items.SalesOrder.Store").
		Preload("Items.SalesOrder.Employee").
		Preload("Items.SalesOrder.Items").
		Preload("Items.SalesOrder.Items.Product").
		// Legacy: muat SalesTransaction untuk data lama
		Preload("Items.SalesTransaction").
		Preload("Items.SalesTransaction.Store").
		Preload("Items.SalesTransaction.Employee").
		Preload("Items.SalesTransaction.Items.Product")
}

func (r *deliveryRepository) CreateBatch(batch *domain.DeliveryBatch) error {
	return r.db.Create(batch).Error
}

func (r *deliveryRepository) GetBatchByDO(doNo string) (*domain.DeliveryBatch, error) {
	var batch domain.DeliveryBatch
	err := r.preloadBatch(r.db).
		Where("delivery_order_no = ?", doNo).First(&batch).Error
	return &batch, err
}

func (r *deliveryRepository) GetBatchByID(id uuid.UUID) (*domain.DeliveryBatch, error) {
	var batch domain.DeliveryBatch
	err := r.preloadBatch(r.db).First(&batch, id).Error
	return &batch, err
}

func (r *deliveryRepository) UpdateBatch(batch *domain.DeliveryBatch) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// If Items are provided, we need to replace them
		// We manually delete to avoid NOT NULL constraint errors with Association.Replace
		if batch.Items != nil {
			if err := tx.Where("delivery_batch_id = ?", batch.ID).Delete(&domain.DeliveryItem{}).Error; err != nil {
				return err
			}
		}

		// Save the batch and its associations
		return tx.Save(batch).Error
	})
}

func (r *deliveryRepository) UpdateItem(item *domain.DeliveryItem) error {
	return r.db.Save(item).Error
}

func (r *deliveryRepository) GetBatchesByDriver(driverID uuid.UUID) ([]domain.DeliveryBatch, error) {
	var batches []domain.DeliveryBatch
	now := time.Now()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	err := r.preloadBatch(r.db).
		Where("driver_id = ? AND (status NOT IN ? OR finished_at >= ?)",
			driverID,
			[]domain.DeliveryBatchStatus{domain.DeliveryBatchCompleted, domain.DeliveryBatchWaitingApproval},
			startOfDay).
		Order("created_at DESC").Find(&batches).Error
	return batches, err
}

func (r *deliveryRepository) GetBatchesHistoryByDriver(driverID uuid.UUID) ([]domain.DeliveryBatch, error) {
	var batches []domain.DeliveryBatch
	err := r.db.
		Preload("Items.SalesOrder.Store").
		Preload("Items.SalesOrder.Items.Product").
		Preload("Items.SalesTransaction.Store").
		Preload("Items.SalesTransaction.Items.Product").
		Where("driver_id = ? AND status = ?", driverID, domain.DeliveryBatchCompleted).
		Order("finished_at DESC").Find(&batches).Error
	return batches, err
}

func (r *deliveryRepository) ListBatches() ([]domain.DeliveryBatch, error) {
	var batches []domain.DeliveryBatch
	err := r.preloadBatch(r.db).
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

func (r *deliveryRepository) GetItemBySONumber(soNumber string) (*domain.DeliveryItem, error) {
	var item domain.DeliveryItem
	err := r.db.Preload("SalesOrder").
		Preload("SalesOrder.Store").
		Preload("SalesOrder.Items.Product").
		Joins("JOIN sales_orders ON sales_orders.id = delivery_items.sales_order_id").
		Where("sales_orders.so_number = ?", soNumber).
		First(&item).Error
	return &item, err
}

func (r *deliveryRepository) DeleteBatch(id uuid.UUID) error {
	return r.db.Delete(&domain.DeliveryBatch{}, id).Error
}

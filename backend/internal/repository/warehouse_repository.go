package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type WarehouseRepository interface {
	// Stock
	GetStock(branchID, productID uuid.UUID) (*domain.WarehouseStock, error)
	UpdateStock(stock *domain.WarehouseStock) error
	GetStocksByBranchID(branchID uuid.UUID) ([]domain.WarehouseStock, error)

	// Transfers
	GetTransfersByBranch(branchID uuid.UUID) ([]domain.ProductTransfer, error)
	GetPendingTransfers(branchID uuid.UUID) ([]domain.ProductTransfer, error)
	GetTransferByID(id uuid.UUID) (*domain.ProductTransfer, error)
	GetTransferByDO(doNo string) (*domain.ProductTransfer, error)
	UpdateTransfer(transfer *domain.ProductTransfer) error

	// Logs
	CreateLog(log *domain.WarehouseLog) error
	GetLogsByBranchID(branchID uuid.UUID) ([]domain.WarehouseLog, error)
}

type warehouseRepository struct {
	db *gorm.DB
}

func NewWarehouseRepository(db *gorm.DB) WarehouseRepository {
	return &warehouseRepository{db}
}

func (r *warehouseRepository) GetStock(branchID, productID uuid.UUID) (*domain.WarehouseStock, error) {
	var stock domain.WarehouseStock
	err := r.db.Preload("Branch").Preload("Product").
		Where("branch_id = ? AND product_id = ?", branchID, productID).First(&stock).Error
	if err == gorm.ErrRecordNotFound {
		return &domain.WarehouseStock{BranchID: branchID, ProductID: productID, Quantity: 0}, nil
	}
	return &stock, err
}

func (r *warehouseRepository) UpdateStock(stock *domain.WarehouseStock) error {
	if stock.ID == uuid.Nil {
		return r.db.Create(stock).Error
	}
	return r.db.Save(stock).Error
}

func (r *warehouseRepository) GetStocksByBranchID(branchID uuid.UUID) ([]domain.WarehouseStock, error) {
	var stocks []domain.WarehouseStock
	err := r.db.Preload("Product").Where("branch_id = ?", branchID).Find(&stocks).Error
	return stocks, err
}

func (r *warehouseRepository) GetTransfersByBranch(branchID uuid.UUID) ([]domain.ProductTransfer, error) {
	var transfers []domain.ProductTransfer
	err := r.db.Preload("Product").Preload("FromFactory").
		Where("to_branch_id = ?", branchID).
		Order("created_at desc").Find(&transfers).Error
	return transfers, err
}

func (r *warehouseRepository) GetPendingTransfers(branchID uuid.UUID) ([]domain.ProductTransfer, error) {
	var transfers []domain.ProductTransfer
	err := r.db.Preload("Product").Preload("FromFactory").
		Where("to_branch_id = ? AND status IN ?", branchID, []string{"REQUESTED", "SHIPPED"}).
		Order("created_at desc").Find(&transfers).Error
	return transfers, err
}

func (r *warehouseRepository) GetTransferByID(id uuid.UUID) (*domain.ProductTransfer, error) {
	var transfer domain.ProductTransfer
	err := r.db.First(&transfer, "id = ?", id).Error
	return &transfer, err
}

func (r *warehouseRepository) GetTransferByDO(doNo string) (*domain.ProductTransfer, error) {
	var transfer domain.ProductTransfer
	err := r.db.Preload("Product").Preload("FromFactory").Where("delivery_order_no = ?", doNo).First(&transfer).Error
	if err != nil {
		return nil, err
	}
	return &transfer, nil
}

func (r *warehouseRepository) UpdateTransfer(transfer *domain.ProductTransfer) error {
	return r.db.Save(transfer).Error
}

func (r *warehouseRepository) CreateLog(log *domain.WarehouseLog) error {
	return r.db.Create(log).Error
}

func (r *warehouseRepository) GetLogsByBranchID(branchID uuid.UUID) ([]domain.WarehouseLog, error) {
	var logs []domain.WarehouseLog
	err := r.db.Preload("Product").Where("branch_id = ?", branchID).Order("created_at desc").Find(&logs).Error
	return logs, err
}

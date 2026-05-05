package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type SalesTransferRepository interface {
	// Sales Stock
	GetSalesStock(employeeID, productID uuid.UUID) (*domain.SalesStock, error)
	UpdateSalesStock(stock *domain.SalesStock) error
	GetStocksByEmployeeID(employeeID uuid.UUID) ([]domain.SalesStock, error)

	// Sales Transfers
	CreateTransfer(transfer *domain.SalesTransfer) error
	UpdateTransfer(transfer *domain.SalesTransfer) error
	GetTransferByID(id uuid.UUID) (*domain.SalesTransfer, error)
	GetTransfersByBranch(branchID uuid.UUID) ([]domain.SalesTransfer, error)
	GetTransfersByEmployee(employeeID uuid.UUID) ([]domain.SalesTransfer, error)
	DeleteTransfer(id uuid.UUID) error
}

type salesTransferRepository struct {
	db *gorm.DB
}

func NewSalesTransferRepository(db *gorm.DB) SalesTransferRepository {
	return &salesTransferRepository{db}
}

func (r *salesTransferRepository) GetSalesStock(employeeID, productID uuid.UUID) (*domain.SalesStock, error) {
	var stock domain.SalesStock
	err := r.db.Preload("Product").
		Where("employee_id = ? AND product_id = ?", employeeID, productID).First(&stock).Error
	if err == gorm.ErrRecordNotFound {
		return &domain.SalesStock{EmployeeID: employeeID, ProductID: productID, Quantity: 0}, nil
	}
	return &stock, err
}

func (r *salesTransferRepository) UpdateSalesStock(stock *domain.SalesStock) error {
	if stock.ID == uuid.Nil {
		return r.db.Create(stock).Error
	}
	return r.db.Save(stock).Error
}

func (r *salesTransferRepository) GetStocksByEmployeeID(employeeID uuid.UUID) ([]domain.SalesStock, error) {
	var stocks []domain.SalesStock
	err := r.db.Preload("Product").Where("employee_id = ?", employeeID).Find(&stocks).Error
	return stocks, err
}

func (r *salesTransferRepository) CreateTransfer(transfer *domain.SalesTransfer) error {
	return r.db.Create(transfer).Error
}

func (r *salesTransferRepository) UpdateTransfer(transfer *domain.SalesTransfer) error {
	return r.db.Save(transfer).Error
}

func (r *salesTransferRepository) GetTransferByID(id uuid.UUID) (*domain.SalesTransfer, error) {
	var transfer domain.SalesTransfer
	err := r.db.Preload("Product").Preload("Employee").Preload("Branch").
		First(&transfer, "id = ?", id).Error
	return &transfer, err
}

func (r *salesTransferRepository) GetTransfersByBranch(branchID uuid.UUID) ([]domain.SalesTransfer, error) {
	var transfers []domain.SalesTransfer
	err := r.db.Preload("Product").Preload("Employee").
		Where("branch_id = ?", branchID).
		Order("created_at desc").Find(&transfers).Error
	return transfers, err
}

func (r *salesTransferRepository) GetTransfersByEmployee(employeeID uuid.UUID) ([]domain.SalesTransfer, error) {
	var transfers []domain.SalesTransfer
	err := r.db.Preload("Product").Preload("Branch").
		Where("employee_id = ?", employeeID).
		Order("created_at desc").Find(&transfers).Error
	return transfers, err
}

func (r *salesTransferRepository) DeleteTransfer(id uuid.UUID) error {
	return r.db.Delete(&domain.SalesTransfer{}, "id = ?", id).Error
}

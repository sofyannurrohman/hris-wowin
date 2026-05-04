package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type FactoryRepository interface {
	// Factory
	CreateFactory(factory *domain.Factory) error
	GetFactoryByID(id uuid.UUID) (*domain.Factory, error)
	GetFactoriesByCompanyID(companyID uuid.UUID) ([]domain.Factory, error)
	UpdateFactory(factory *domain.Factory) error
	DeleteFactory(id uuid.UUID) error

	// Product
	CreateProduct(product *domain.Product) error
	GetProductsByCompanyID(companyID uuid.UUID) ([]domain.Product, error)
	GetProductByID(id uuid.UUID) (*domain.Product, error)
	UpdateProduct(product *domain.Product) error
	DeleteProduct(id uuid.UUID) error

	// Stock
	GetStock(factoryID, productID uuid.UUID) (*domain.FactoryStock, error)
	UpdateStock(stock *domain.FactoryStock) error
	GetStocksByFactoryID(factoryID uuid.UUID) ([]domain.FactoryStock, error)

	// Logs
	CreateProductionLog(log *domain.ProductionLog) error
	GetProductionLogsByFactoryID(factoryID uuid.UUID) ([]domain.ProductionLog, error)
	CreateInventoryLog(log *domain.FactoryInventoryLog) error
	GetInventoryLogsByFactoryID(factoryID uuid.UUID) ([]domain.FactoryInventoryLog, error)

	// Transfer
	CreateTransfer(transfer *domain.ProductTransfer) error
	GetTransfersByFactoryID(factoryID uuid.UUID) ([]domain.ProductTransfer, error)
	GetTransferByID(id uuid.UUID) (*domain.ProductTransfer, error)
	UpdateTransfer(transfer *domain.ProductTransfer) error
	UpdateTransferStatus(id uuid.UUID, status string) error
}

type factoryRepository struct {
	db *gorm.DB
}

func NewFactoryRepository(db *gorm.DB) FactoryRepository {
	return &factoryRepository{db}
}

func (r *factoryRepository) CreateFactory(factory *domain.Factory) error {
	return r.db.Create(factory).Error
}

func (r *factoryRepository) GetFactoryByID(id uuid.UUID) (*domain.Factory, error) {
	var factory domain.Factory
	err := r.db.Preload("Branch").First(&factory, "id = ?", id).Error
	return &factory, err
}

func (r *factoryRepository) GetFactoriesByCompanyID(companyID uuid.UUID) ([]domain.Factory, error) {
	var factories []domain.Factory
	err := r.db.Preload("Branch").Find(&factories, "company_id = ?", companyID).Error
	return factories, err
}

func (r *factoryRepository) UpdateFactory(factory *domain.Factory) error {
	return r.db.Save(factory).Error
}

func (r *factoryRepository) DeleteFactory(id uuid.UUID) error {
	return r.db.Delete(&domain.Factory{}, "id = ?", id).Error
}

func (r *factoryRepository) CreateProduct(product *domain.Product) error {
	return r.db.Create(product).Error
}

func (r *factoryRepository) GetProductsByCompanyID(companyID uuid.UUID) ([]domain.Product, error) {
	var products []domain.Product
	err := r.db.Find(&products, "company_id = ?", companyID).Error
	return products, err
}

func (r *factoryRepository) GetProductByID(id uuid.UUID) (*domain.Product, error) {
	var product domain.Product
	err := r.db.First(&product, "id = ?", id).Error
	return &product, err
}

func (r *factoryRepository) UpdateProduct(product *domain.Product) error {
	return r.db.Save(product).Error
}

func (r *factoryRepository) DeleteProduct(id uuid.UUID) error {
	return r.db.Delete(&domain.Product{}, "id = ?", id).Error
}

func (r *factoryRepository) GetStock(factoryID, productID uuid.UUID) (*domain.FactoryStock, error) {
	var stock domain.FactoryStock
	err := r.db.Where("factory_id = ? AND product_id = ?", factoryID, productID).First(&stock).Error
	if err == gorm.ErrRecordNotFound {
		return &domain.FactoryStock{FactoryID: factoryID, ProductID: productID, Quantity: 0}, nil
	}
	return &stock, err
}

func (r *factoryRepository) UpdateStock(stock *domain.FactoryStock) error {
	if stock.ID == uuid.Nil {
		return r.db.Create(stock).Error
	}
	return r.db.Save(stock).Error
}

func (r *factoryRepository) GetStocksByFactoryID(factoryID uuid.UUID) ([]domain.FactoryStock, error) {
	var stocks []domain.FactoryStock
	err := r.db.Preload("Product").Where("factory_id = ?", factoryID).Find(&stocks).Error
	return stocks, err
}

func (r *factoryRepository) CreateProductionLog(log *domain.ProductionLog) error {
	return r.db.Create(log).Error
}

func (r *factoryRepository) GetProductionLogsByFactoryID(factoryID uuid.UUID) ([]domain.ProductionLog, error) {
	var logs []domain.ProductionLog
	err := r.db.Preload("Product").Preload("Employee").Where("factory_id = ?", factoryID).Order("production_date desc").Find(&logs).Error
	return logs, err
}

func (r *factoryRepository) CreateInventoryLog(log *domain.FactoryInventoryLog) error {
	return r.db.Create(log).Error
}

func (r *factoryRepository) GetInventoryLogsByFactoryID(factoryID uuid.UUID) ([]domain.FactoryInventoryLog, error) {
	var logs []domain.FactoryInventoryLog
	err := r.db.Preload("Product").Where("factory_id = ?", factoryID).Order("created_at desc").Find(&logs).Error
	return logs, err
}

func (r *factoryRepository) CreateTransfer(transfer *domain.ProductTransfer) error {
	return r.db.Create(transfer).Error
}

func (r *factoryRepository) GetTransfersByFactoryID(factoryID uuid.UUID) ([]domain.ProductTransfer, error) {
	var transfers []domain.ProductTransfer
	err := r.db.Preload("Product").Preload("ToBranch").Where("from_factory_id = ?", factoryID).Order("created_at desc").Find(&transfers).Error
	return transfers, err
}

func (r *factoryRepository) GetTransferByID(id uuid.UUID) (*domain.ProductTransfer, error) {
	var transfer domain.ProductTransfer
	err := r.db.First(&transfer, "id = ?", id).Error
	return &transfer, err
}

func (r *factoryRepository) UpdateTransfer(transfer *domain.ProductTransfer) error {
	return r.db.Save(transfer).Error
}

func (r *factoryRepository) UpdateTransferStatus(id uuid.UUID, status string) error {
	return r.db.Model(&domain.ProductTransfer{}).Where("id = ?", id).Update("status", status).Error
}

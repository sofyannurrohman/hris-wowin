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
	GetStock(factoryID, productID uuid.UUID, batchNo string) (*domain.FactoryStock, error)
	UpdateStock(stock *domain.FactoryStock) error
	GetStocksByFactoryID(factoryID uuid.UUID) ([]domain.FactoryStock, error)
	GetAllStocksByCompanyID(companyID uuid.UUID) ([]domain.FactoryStock, error)
	GetAvailableBatches(factoryID, productID uuid.UUID) ([]domain.FactoryStock, error)

	// Logs
	CreateProductionLog(log *domain.ProductionLog) error
	GetProductionLogByID(id uuid.UUID) (*domain.ProductionLog, error)
	GetProductionLogsByFactoryID(factoryID uuid.UUID) ([]domain.ProductionLog, error)
	GetAllProductionLogsByCompanyID(companyID uuid.UUID) ([]domain.ProductionLog, error)
	UpdateProductionLog(log *domain.ProductionLog) error
	DeleteProductionLog(id uuid.UUID) error
	CreateInventoryLog(log *domain.FactoryInventoryLog) error
	GetInventoryLogsByFactoryID(factoryID uuid.UUID) ([]domain.FactoryInventoryLog, error)

	// Transfer
	CreateTransfer(transfer *domain.ProductTransfer) error
	GetTransfersByFactoryID(factoryID uuid.UUID) ([]domain.ProductTransfer, error)
	GetAllTransfersByCompanyID(companyID uuid.UUID) ([]domain.ProductTransfer, error)
	GetTransferByID(id uuid.UUID) (*domain.ProductTransfer, error)
	UpdateTransfer(transfer *domain.ProductTransfer) error
	UpdateTransferStatus(id uuid.UUID, status string) error
	
	// Recipe
	CreateRecipe(recipe *domain.ProductionRecipe) error
	GetRecipeByFinishedProduct(productID uuid.UUID) (*domain.ProductionRecipe, error)
	GetRecipesByCompany(companyID uuid.UUID) ([]domain.ProductionRecipe, error)
	DeleteRecipe(id uuid.UUID) error
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
	return r.db.Model(factory).Select("Name", "Location", "BranchID").Updates(factory).Error
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
	return r.db.Model(product).Select("Name", "SKU", "Unit", "Category", "Brand", "Weight", "WeightUnit", "CostPrice", "SellingPrice", "Description", "Specs", "ImageURL").Updates(product).Error
}

func (r *factoryRepository) DeleteProduct(id uuid.UUID) error {
	return r.db.Delete(&domain.Product{}, "id = ?", id).Error
}

func (r *factoryRepository) GetStock(factoryID, productID uuid.UUID, batchNo string) (*domain.FactoryStock, error) {
	var stock domain.FactoryStock
	err := r.db.Where("factory_id = ? AND product_id = ? AND batch_no = ?", factoryID, productID, batchNo).First(&stock).Error
	if err == gorm.ErrRecordNotFound {
		return &domain.FactoryStock{FactoryID: factoryID, ProductID: productID, BatchNo: batchNo, Quantity: 0}, nil
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

func (r *factoryRepository) GetAllStocksByCompanyID(companyID uuid.UUID) ([]domain.FactoryStock, error) {
	var stocks []domain.FactoryStock
	err := r.db.Preload("Product").Preload("Factory").
		Joins("JOIN factories ON factories.id = factory_stocks.factory_id").
		Where("factories.company_id = ?", companyID).
		Find(&stocks).Error
	return stocks, err
}

func (r *factoryRepository) GetAvailableBatches(factoryID, productID uuid.UUID) ([]domain.FactoryStock, error) {
	var stocks []domain.FactoryStock
	err := r.db.Where("factory_id = ? AND product_id = ? AND quantity > 0 AND batch_no != 'BACKORDER'", factoryID, productID).
		Order("expiry_date ASC").
		Find(&stocks).Error
	return stocks, err
}

func (r *factoryRepository) CreateProductionLog(log *domain.ProductionLog) error {
	return r.db.Create(log).Error
}

func (r *factoryRepository) GetProductionLogByID(id uuid.UUID) (*domain.ProductionLog, error) {
	var log domain.ProductionLog
	err := r.db.First(&log, "id = ?", id).Error
	return &log, err
}

func (r *factoryRepository) GetProductionLogsByFactoryID(factoryID uuid.UUID) ([]domain.ProductionLog, error) {
	var logs []domain.ProductionLog
	err := r.db.Preload("Product").Preload("Employee").Where("factory_id = ?", factoryID).Order("production_date desc").Find(&logs).Error
	return logs, err
}

func (r *factoryRepository) GetAllProductionLogsByCompanyID(companyID uuid.UUID) ([]domain.ProductionLog, error) {
	var logs []domain.ProductionLog
	err := r.db.Preload("Product").Preload("Employee").Preload("Factory").
		Joins("JOIN factories ON factories.id = production_logs.factory_id").
		Where("factories.company_id = ?", companyID).
		Order("production_date desc").Find(&logs).Error
	return logs, err
}

func (r *factoryRepository) UpdateProductionLog(log *domain.ProductionLog) error {
	return r.db.Save(log).Error
}

func (r *factoryRepository) DeleteProductionLog(id uuid.UUID) error {
	return r.db.Delete(&domain.ProductionLog{}, "id = ?", id).Error
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

func (r *factoryRepository) GetAllTransfersByCompanyID(companyID uuid.UUID) ([]domain.ProductTransfer, error) {
	var transfers []domain.ProductTransfer
	err := r.db.Preload("Product").Preload("ToBranch").Preload("FromFactory").
		Joins("JOIN factories ON factories.id = product_transfers.from_factory_id").
		Where("factories.company_id = ?", companyID).
		Order("created_at desc").Find(&transfers).Error
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

func (r *factoryRepository) CreateRecipe(recipe *domain.ProductionRecipe) error {
	return r.db.Create(recipe).Error
}

func (r *factoryRepository) GetRecipeByFinishedProduct(productID uuid.UUID) (*domain.ProductionRecipe, error) {
	var recipe domain.ProductionRecipe
	err := r.db.Preload("Items.RawProduct").Where("finished_product_id = ?", productID).First(&recipe).Error
	if err == gorm.ErrRecordNotFound {
		return nil, nil
	}
	return &recipe, err
}

func (r *factoryRepository) GetRecipesByCompany(companyID uuid.UUID) ([]domain.ProductionRecipe, error) {
	var recipes []domain.ProductionRecipe
	err := r.db.Preload("FinishedProduct").
		Joins("JOIN products ON products.id = production_recipes.finished_product_id").
		Where("products.company_id = ?", companyID).
		Find(&recipes).Error
	return recipes, err
}

func (r *factoryRepository) DeleteRecipe(id uuid.UUID) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Delete(&domain.ProductionRecipeItem{}, "recipe_id = ?", id).Error; err != nil {
			return err
		}
		return tx.Delete(&domain.ProductionRecipe{}, "id = ?", id).Error
	})
}


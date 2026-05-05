package usecase

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"gorm.io/gorm"
)

type FactoryUsecase interface {
	// Factory
	CreateFactory(factory *domain.Factory) error
	GetAllFactories(companyID uuid.UUID) ([]domain.Factory, error)
	GetFactoryDetail(id uuid.UUID) (*domain.Factory, error)
	UpdateFactory(factory *domain.Factory) error
	DeleteFactory(id uuid.UUID) error

	// Product
	CreateProduct(product *domain.Product) error
	GetProducts(companyID uuid.UUID) ([]domain.Product, error)
	UpdateProduct(product *domain.Product) error
	DeleteProduct(id uuid.UUID) error

	// Production
	LogProduction(factoryID, productID, employeeID uuid.UUID, quantity, cartonCount, piecesPerCarton int, notes string) error
	GetProductionHistory(factoryID uuid.UUID) ([]domain.ProductionLog, error)
	GetAllProductionHistory(companyID uuid.UUID) ([]domain.ProductionLog, error)
	UpdateProductionLog(id uuid.UUID, quantity, cartonCount, piecesPerCarton int, notes string) error
	DeleteProductionLog(id uuid.UUID) error

	// Inventory
	GetFactoryInventory(factoryID uuid.UUID) ([]domain.FactoryStock, error)
	GetAllInventory(companyID uuid.UUID) ([]domain.FactoryStock, error)
	GetInventoryLogs(factoryID uuid.UUID) ([]domain.FactoryInventoryLog, error)
	AdjustStock(factoryID, productID uuid.UUID, quantity int, reason string) error

	// Transfer & Logistics
	RequestShipment(fromFactoryID, toBranchID uuid.UUID, items []domain.ProductTransferItem, notes string) error
	ApproveTransfer(transferID uuid.UUID) error
	ExecuteApprovedShipment(transferID uuid.UUID) error
	GetTransferHistory(factoryID uuid.UUID) ([]domain.ProductTransfer, error)
	GetAllTransfers(companyID uuid.UUID) ([]domain.ProductTransfer, error)
}

type factoryUsecase struct {
	repo repository.FactoryRepository
	db   *gorm.DB
}

func NewFactoryUsecase(repo repository.FactoryRepository, db *gorm.DB) FactoryUsecase {
	return &factoryUsecase{repo, db}
}

func (u *factoryUsecase) CreateFactory(factory *domain.Factory) error {
	return u.repo.CreateFactory(factory)
}

func (u *factoryUsecase) GetAllFactories(companyID uuid.UUID) ([]domain.Factory, error) {
	return u.repo.GetFactoriesByCompanyID(companyID)
}

func (u *factoryUsecase) GetFactoryDetail(id uuid.UUID) (*domain.Factory, error) {
	return u.repo.GetFactoryByID(id)
}

func (u *factoryUsecase) UpdateFactory(factory *domain.Factory) error {
	return u.repo.UpdateFactory(factory)
}

func (u *factoryUsecase) DeleteFactory(id uuid.UUID) error {
	return u.repo.DeleteFactory(id)
}

func (u *factoryUsecase) CreateProduct(product *domain.Product) error {
	return u.repo.CreateProduct(product)
}

func (u *factoryUsecase) GetProducts(companyID uuid.UUID) ([]domain.Product, error) {
	return u.repo.GetProductsByCompanyID(companyID)
}

func (u *factoryUsecase) UpdateProduct(product *domain.Product) error {
	return u.repo.UpdateProduct(product)
}

func (u *factoryUsecase) DeleteProduct(id uuid.UUID) error {
	return u.repo.DeleteProduct(id)
}

func (u *factoryUsecase) LogProduction(factoryID, productID, employeeID uuid.UUID, quantity, cartonCount, piecesPerCarton int, notes string) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)

		productionLog := &domain.ProductionLog{
			FactoryID:       factoryID,
			ProductID:       productID,
			EmployeeID:      employeeID,
			Quantity:        quantity,
			CartonCount:     cartonCount,
			PiecesPerCarton: piecesPerCarton,
			ProductionDate:  time.Now(),
			Notes:           notes,
		}
		if err := repo.CreateProductionLog(productionLog); err != nil {
			return err
		}

		stock, err := repo.GetStock(factoryID, productID)
		if err != nil && err != gorm.ErrRecordNotFound {
			return err
		}
		stock.Quantity += quantity
		if err := repo.UpdateStock(stock); err != nil {
			return err
		}

		inventoryLog := &domain.FactoryInventoryLog{
			FactoryID: factoryID,
			ProductID: productID,
			Type:      "IN",
			Source:    "PRODUCTION",
			Quantity:  quantity,
		}
		return repo.CreateInventoryLog(inventoryLog)
	})
}

func (u *factoryUsecase) GetProductionHistory(factoryID uuid.UUID) ([]domain.ProductionLog, error) {
	return u.repo.GetProductionLogsByFactoryID(factoryID)
}

func (u *factoryUsecase) GetAllProductionHistory(companyID uuid.UUID) ([]domain.ProductionLog, error) {
	return u.repo.GetAllProductionLogsByCompanyID(companyID)
}

func (u *factoryUsecase) UpdateProductionLog(id uuid.UUID, quantity, cartonCount, piecesPerCarton int, notes string) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)
		log, err := repo.GetProductionLogByID(id)
		if err != nil {
			return err
		}

		// Adjust Stock (diff)
		diff := quantity - log.Quantity
		stock, err := repo.GetStock(log.FactoryID, log.ProductID)
		if err != nil {
			return err
		}
		stock.Quantity += diff
		if err := repo.UpdateStock(stock); err != nil {
			return err
		}

		log.Quantity = quantity
		log.CartonCount = cartonCount
		log.PiecesPerCarton = piecesPerCarton
		log.Notes = notes
		return repo.UpdateProductionLog(log)
	})
}

func (u *factoryUsecase) DeleteProductionLog(id uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)
		log, err := repo.GetProductionLogByID(id)
		if err != nil {
			return err
		}

		// Reverse Stock
		stock, err := repo.GetStock(log.FactoryID, log.ProductID)
		if err != nil {
			return err
		}
		stock.Quantity -= log.Quantity
		if err := repo.UpdateStock(stock); err != nil {
			return err
		}

		return repo.DeleteProductionLog(id)
	})
}

func (u *factoryUsecase) GetFactoryInventory(factoryID uuid.UUID) ([]domain.FactoryStock, error) {
	return u.repo.GetStocksByFactoryID(factoryID)
}

func (u *factoryUsecase) GetAllInventory(companyID uuid.UUID) ([]domain.FactoryStock, error) {
	return u.repo.GetAllStocksByCompanyID(companyID)
}

func (u *factoryUsecase) GetInventoryLogs(factoryID uuid.UUID) ([]domain.FactoryInventoryLog, error) {
	return u.repo.GetInventoryLogsByFactoryID(factoryID)
}

func (u *factoryUsecase) AdjustStock(factoryID, productID uuid.UUID, quantity int, reason string) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)
		stock, err := repo.GetStock(factoryID, productID)
		if err != nil {
			return err
		}

		stock.Quantity = quantity
		if err := repo.UpdateStock(stock); err != nil {
			return err
		}

		inventoryLog := &domain.FactoryInventoryLog{
			FactoryID: factoryID,
			ProductID: productID,
			Type:      "ADJUST",
			Source:    reason,
			Quantity:  quantity,
		}
		return repo.CreateInventoryLog(inventoryLog)
	})
}

type ShipmentItem struct {
	ProductID uuid.UUID
	Quantity  int
}

func (u *factoryUsecase) RequestShipment(fromFactoryID, toBranchID uuid.UUID, items []domain.ProductTransferItem, notes string) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)

		// Generate a common DO number for this shipment
		doNo := fmt.Sprintf("SJ/%s/%s", time.Now().Format("20060102"), strings.ToUpper(uuid.New().String()[:6]))

		for _, item := range items {
			// Get Product for weight calculation
			product, err := repo.GetProductByID(item.ProductID)
			if err != nil {
				return err
			}

			totalWeight := float64(item.Quantity) * product.Weight

			transfer := &domain.ProductTransfer{
				FromFactoryID:   fromFactoryID,
				ToBranchID:      toBranchID,
				ProductID:       item.ProductID,
				Quantity:        item.Quantity,
				TotalWeight:     totalWeight,
				Status:          "REQUESTED",
				DeliveryOrderNo: doNo,
				Notes:           notes,
			}
			if err := repo.CreateTransfer(transfer); err != nil {
				return err
			}
		}
		return nil
	})
}

func (u *factoryUsecase) ApproveTransfer(transferID uuid.UUID) error {
	return u.repo.UpdateTransferStatus(transferID, "APPROVED")
}

func (u *factoryUsecase) ExecuteApprovedShipment(transferID uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)

		// 1. Get Transfer
		transfer, err := repo.GetTransferByID(transferID)
		if err != nil {
			return err
		}
		if transfer.Status != "APPROVED" && transfer.Status != "REQUESTED" {
			return errors.New("only APPROVED or REQUESTED transfers can be shipped")
		}

		// 2. Check Factory Stock
		stock, err := repo.GetStock(transfer.FromFactoryID, transfer.ProductID)
		if err != nil {
			return err
		}
		if stock.Quantity < transfer.Quantity {
			return errors.New("insufficient stock in factory for this shipment")
		}

		// 3. Reduce Factory Stock
		stock.Quantity -= transfer.Quantity
		if err := repo.UpdateStock(stock); err != nil {
			return err
		}

		// 4. Update Status to SHIPPED and Generate DO No
		now := time.Now()
		transfer.Status = "SHIPPED"
		transfer.ShippedAt = &now
		// Format: DO-[YYYYMMDD]-[UUID8]
		transfer.DeliveryOrderNo = fmt.Sprintf("DO-%s-%s", now.Format("20060102"), uuid.New().String()[:8])

		if err := repo.UpdateTransfer(transfer); err != nil {
			return err
		}

		// 5. Create Inventory Log
		inventoryLog := &domain.FactoryInventoryLog{
			FactoryID: transfer.FromFactoryID,
			ProductID: transfer.ProductID,
			Type:      "OUT",
			Source:    "TRANSFER TO BRANCH",
			Quantity:  transfer.Quantity,
		}
		return repo.CreateInventoryLog(inventoryLog)
	})
}

func (u *factoryUsecase) GetTransferHistory(factoryID uuid.UUID) ([]domain.ProductTransfer, error) {
	return u.repo.GetTransfersByFactoryID(factoryID)
}

func (u *factoryUsecase) GetAllTransfers(companyID uuid.UUID) ([]domain.ProductTransfer, error) {
	return u.repo.GetAllTransfersByCompanyID(companyID)
}

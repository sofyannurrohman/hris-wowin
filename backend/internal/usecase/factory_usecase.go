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
	LogProduction(factoryID, productID, employeeID uuid.UUID, quantity, cartonCount, piecesPerCarton int, notes string, batchNo string, expiryDate *time.Time) error
	GetProductionHistory(factoryID uuid.UUID) ([]domain.ProductionLog, error)
	GetAllProductionHistory(companyID uuid.UUID) ([]domain.ProductionLog, error)
	UpdateProductionLog(id uuid.UUID, quantity, cartonCount, piecesPerCarton int, notes string) error
	DeleteProductionLog(id uuid.UUID) error

	// Inventory
	GetFactoryInventory(factoryID uuid.UUID) ([]domain.FactoryStock, error)
	GetAllInventory(companyID uuid.UUID) ([]domain.FactoryStock, error)
	GetInventoryLogs(factoryID uuid.UUID) ([]domain.FactoryInventoryLog, error)
	AdjustStock(factoryID, productID uuid.UUID, quantity int, reason string, batchNo string) error

	// Transfer & Logistics
	RequestShipment(fromFactoryID, toBranchID uuid.UUID, items []domain.ProductTransferItem, notes string, targetShipmentDate, estimatedArrival *time.Time, initiatedBy string, vehicleID, driverID *uuid.UUID) error
	ApproveTransfer(transferID uuid.UUID) error
	ExecuteApprovedShipment(transferID uuid.UUID) error
	GetTransferHistory(factoryID uuid.UUID) ([]domain.ProductTransfer, error)
	GetAllTransfers(companyID uuid.UUID) ([]domain.ProductTransfer, error)
	UpdateTransfer(id uuid.UUID, data map[string]interface{}) error
	DeleteTransfer(id uuid.UUID) error

	// Recipe
	CreateRecipe(recipe *domain.ProductionRecipe) error
	GetRecipes(companyID uuid.UUID) ([]domain.ProductionRecipe, error)
	GetRecipeByProduct(productID uuid.UUID) (*domain.ProductionRecipe, error)
	DeleteRecipe(id uuid.UUID) error

	// Dashboard Demand
	GetBackorderDemand(companyID uuid.UUID) ([]BackorderDemand, error)
	GetDashboardStats(companyID uuid.UUID) (*domain.FactoryDashboardStats, error)
}

type BackorderDemand struct {
	ProductID   uuid.UUID `json:"product_id"`
	ProductName string    `json:"product_name"`
	TotalQty    int       `json:"total_qty"`
	OrderCount  int       `json:"order_count"`
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

func (u *factoryUsecase) LogProduction(factoryID, productID, employeeID uuid.UUID, quantity, cartonCount, piecesPerCarton int, notes string, batchNo string, expiryDate *time.Time) error {
	if batchNo == "" {
		batchNo = "DEFAULT"
	}
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)

		// 1. Ambil Resep untuk produk ini
		recipe, err := repo.GetRecipeByFinishedProduct(productID)
		if err != nil {
			return err
		}

		// 2. Jika ada resep, potong stok bahan baku secara otomatis (FEFO)
		if recipe != nil {
			for _, item := range recipe.Items {
				neededQty := float64(quantity) * item.Quantity
				
				// Ambil semua batch bahan baku yang tersedia, urutkan berdasarkan expiry (FEFO)
				stocks, err := repo.GetAvailableBatches(factoryID, item.RawProductID)
				if err != nil {
					return err
				}

				totalAvailable := 0
				for _, s := range stocks {
					totalAvailable += s.Quantity
				}

				if float64(totalAvailable) < neededQty {
					return fmt.Errorf("stok bahan baku %s tidak mencukupi (Butuh: %.2f, Ada: %d)", item.RawProduct.Name, neededQty, totalAvailable)
				}

				remainingToDeduct := int(neededQty)
				for i := range stocks {
					s := &stocks[i]
					if remainingToDeduct <= 0 {
						break
					}
					
					deduct := s.Quantity
					if deduct > remainingToDeduct {
						deduct = remainingToDeduct
					}
					
					s.Quantity -= deduct
					remainingToDeduct -= deduct
					
					if err := repo.UpdateStock(s); err != nil {
						return err
					}

					// Catat Log Mutasi Bahan Baku (OUT)
					if err := repo.CreateInventoryLog(&domain.FactoryInventoryLog{
						FactoryID: factoryID,
						ProductID: item.RawProductID,
						Type:      "OUT",
						Source:    "PRODUCTION_CONSUMPTION",
						BatchNo:   s.BatchNo,
						Quantity:  deduct,
					}); err != nil {
						return err
					}
				}
			}
		}
		// 3. Tambahkan stok Barang Jadi
		productionLog := &domain.ProductionLog{
			FactoryID:       factoryID,
			ProductID:       productID,
			BatchNo:         batchNo,
			ExpiryDate:      expiryDate,
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

		stock, err := repo.GetStock(factoryID, productID, batchNo)
		if err != nil && err != gorm.ErrRecordNotFound {
			return err
		}
		stock.Quantity += quantity
		stock.ExpiryDate = expiryDate
		if err := repo.UpdateStock(stock); err != nil {
			return err
		}

		inventoryLog := &domain.FactoryInventoryLog{
			FactoryID: factoryID,
			ProductID: productID,
			Type:      "IN",
			Source:    "PRODUCTION_OUTPUT",
			Quantity:  quantity,
		}
		return repo.CreateInventoryLog(inventoryLog)
	})
}

// --- Recipe Implementations ---

func (u *factoryUsecase) CreateRecipe(recipe *domain.ProductionRecipe) error {
	return u.repo.CreateRecipe(recipe)
}

func (u *factoryUsecase) GetRecipes(companyID uuid.UUID) ([]domain.ProductionRecipe, error) {
	return u.repo.GetRecipesByCompany(companyID)
}

func (u *factoryUsecase) GetRecipeByProduct(productID uuid.UUID) (*domain.ProductionRecipe, error) {
	return u.repo.GetRecipeByFinishedProduct(productID)
}

func (u *factoryUsecase) DeleteRecipe(id uuid.UUID) error {
	return u.repo.DeleteRecipe(id)
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
		stock, err := repo.GetStock(log.FactoryID, log.ProductID, log.BatchNo)
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
		stock, err := repo.GetStock(log.FactoryID, log.ProductID, log.BatchNo)
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

func (u *factoryUsecase) AdjustStock(factoryID, productID uuid.UUID, quantity int, reason string, batchNo string) error {
	if batchNo == "" {
		batchNo = "DEFAULT"
	}
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)
		stock, err := repo.GetStock(factoryID, productID, batchNo)
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

func (u *factoryUsecase) RequestShipment(fromFactoryID, toBranchID uuid.UUID, items []domain.ProductTransferItem, notes string, targetShipmentDate, estimatedArrival *time.Time, initiatedBy string, vehicleID, driverID *uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)

		// 1. If Vehicle is assigned, check capacity
		if vehicleID != nil {
			var vehicle domain.Vehicle
			if err := tx.First(&vehicle, "id = ?", *vehicleID).Error; err != nil {
				return fmt.Errorf("kendaraan tidak ditemukan: %w", err)
			}

			totalRequestWeight := 0.0
			for _, item := range items {
				product, err := repo.GetProductByID(item.ProductID)
				if err != nil {
					return err
				}
				weight := float64(item.Quantity) * float64(item.PcsPerUnit) * product.Weight
				unit := strings.ToUpper(product.WeightUnit)
				if unit == "GR" || unit == "ML" {
					weight /= 1000
				} else if unit == "TON" {
					weight *= 1000
				}
				totalRequestWeight += weight
			}

			if totalRequestWeight > vehicle.Capacity && vehicle.Capacity > 0 {
				return fmt.Errorf("tonase pengiriman (%.2f KG) melebihi kapasitas armada %s (%.2f KG)", totalRequestWeight, vehicle.Name, vehicle.Capacity)
			}
		}

		// 2. Generate a common DO number for this shipment
		doNo := fmt.Sprintf("SJ/%s/%s", time.Now().Format("20060102"), strings.ToUpper(uuid.New().String()[:6]))

		fmt.Printf("DEBUG: Processing Shipment Request with %d items\n", len(items))
		for _, item := range items {
			// Get Product for weight calculation
			product, err := repo.GetProductByID(item.ProductID)
			if err != nil {
				return err
			}

			totalWeight := float64(item.Quantity) * float64(item.PcsPerUnit) * product.Weight
			unit := strings.ToUpper(product.WeightUnit)
			if unit == "GR" || unit == "ML" {
				totalWeight /= 1000
			} else if unit == "TON" {
				totalWeight *= 1000
			}

			status := "REQUESTED"

			transfer := &domain.ProductTransfer{
				FromFactoryID:      fromFactoryID,
				ToBranchID:         toBranchID,
				ProductID:          item.ProductID,
				Quantity:           item.Quantity,
				PcsPerUnit:         item.PcsPerUnit,
				TotalWeight:        totalWeight,
				Status:             status,
				DeliveryOrderNo:    doNo,
				Notes:              notes,
				TargetShipmentDate: targetShipmentDate,
				EstimatedArrival:   estimatedArrival,
				InitiatedBy:        initiatedBy,
				Unit:               item.Unit,
				VehicleID:          vehicleID,
				DriverID:           driverID,
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
		if transfer.Status != "APPROVED" {
			return errors.New("only APPROVED transfers can be shipped")
		}

		// 2. Check Factory Stock (Convert to total pieces)
		totalPieces := transfer.Quantity * transfer.PcsPerUnit
		if transfer.BatchNo == "" {
			transfer.BatchNo = "DEFAULT"
		}
		stock, err := repo.GetStock(transfer.FromFactoryID, transfer.ProductID, transfer.BatchNo)
		if err != nil {
			return err
		}
		if stock.Quantity < totalPieces {
			return errors.New("insufficient stock in factory for this shipment")
		}

		// 3. Reduce Factory Stock
		stock.Quantity -= totalPieces
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
			Quantity:  totalPieces,
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

func (u *factoryUsecase) UpdateTransfer(id uuid.UUID, data map[string]interface{}) error {
	transfer, err := u.repo.GetTransferByID(id)
	if err != nil {
		return err
	}
	if transfer.Status != "REQUESTED" && transfer.Status != "APPROVED" && transfer.Status != "REJECTED" {
		return errors.New("pengiriman yang sudah diproses tidak dapat diubah")
	}

	// Update only allowed fields
	if err := u.db.Model(transfer).Updates(data).Error; err != nil {
		return err
	}

	// If quantity or pcs_per_unit changed, recalculate total_weight
	if _, ok := data["quantity"]; ok || data["pcs_per_unit"] != nil {
		// Re-fetch to get latest values
		updated, _ := u.repo.GetTransferByID(id)
		product, _ := u.repo.GetProductByID(updated.ProductID)
		
		totalWeight := float64(updated.Quantity) * float64(updated.PcsPerUnit) * product.Weight
		unit := strings.ToUpper(product.WeightUnit)
		if unit == "GR" || unit == "ML" {
			totalWeight /= 1000
		} else if unit == "TON" {
			totalWeight *= 1000
		}
		updated.TotalWeight = totalWeight
		return u.repo.UpdateTransfer(updated)
	}
	
	return nil
}

func (u *factoryUsecase) DeleteTransfer(id uuid.UUID) error {
	transfer, err := u.repo.GetTransferByID(id)
	if err != nil {
		return err
	}
	if transfer.Status != "REQUESTED" && transfer.Status != "APPROVED" && transfer.Status != "REJECTED" {
		return errors.New("pengiriman yang sudah diproses tidak dapat dihapus")
	}

	return u.repo.DeleteTransfer(id)
}

func (u *factoryUsecase) GetBackorderDemand(companyID uuid.UUID) ([]BackorderDemand, error) {
	var results []BackorderDemand
	err := u.db.Table("sales_order_items").
		Select("sales_order_items.product_id, products.name as product_name, SUM(sales_order_items.quantity - sales_order_items.reserved_quantity) as total_qty, COUNT(DISTINCT sales_order_items.sales_order_id) as order_count").
		Joins("JOIN sales_orders ON sales_orders.id = sales_order_items.sales_order_id").
		Joins("JOIN products ON products.id = sales_order_items.product_id").
		Where("sales_orders.company_id = ? AND sales_orders.status = ?", companyID, domain.SOStatusWaitingStock).
		Group("sales_order_items.product_id, products.name").
		Having("total_qty > 0").
		Order("total_qty DESC").
		Scan(&results).Error
	return results, err
}

func (u *factoryUsecase) GetDashboardStats(companyID uuid.UUID) (*domain.FactoryDashboardStats, error) {
	return u.repo.GetDashboardStats(companyID)
}


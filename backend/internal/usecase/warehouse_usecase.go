package usecase

import (
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"gorm.io/gorm"
)

type WarehouseUsecase interface {
	GetInventory(branchID uuid.UUID) ([]domain.WarehouseStock, error)
	GetPendingShipments(branchID uuid.UUID) ([]domain.ProductTransfer, error)
	ReceiveShipment(transferID uuid.UUID, actualQty, damagedQty int) error
	GetTransferByDO(doNo string) (*domain.ProductTransfer, error)
	ReceiveShipmentByDO(doNo string, actualQty, damagedQty int) error
	GetWarehouseLogs(branchID uuid.UUID) ([]domain.WarehouseLog, error)
	GetAllTransfers(branchID uuid.UUID) ([]domain.ProductTransfer, error)
	AdjustStock(branchID, productID uuid.UUID, quantity int, reason string, batchNo string) error
	
	ApproveTransfer(transferID uuid.UUID) error
	RejectTransfer(transferID uuid.UUID, reason string) error
	ConfirmArrival(transferID uuid.UUID) error
	ConfirmShipment(transferID uuid.UUID) error

	// Executor Workflow
	DispatchByInvoice(receiptNo string, branchID uuid.UUID) error
	SetStockLimit(branchID, productID uuid.UUID, limit int, batchNo string) error
}

type warehouseUsecase struct {
	repo      repository.WarehouseRepository
	notifRepo  repository.NotificationRepository
	salesRepo  repository.SalesTransactionRepository
	soRepo     repository.SalesOrderRepository
	db        *gorm.DB
}

func NewWarehouseUsecase(
	repo repository.WarehouseRepository, 
	notifRepo repository.NotificationRepository, 
	salesRepo repository.SalesTransactionRepository,
	soRepo repository.SalesOrderRepository,
	db *gorm.DB,
) WarehouseUsecase {
	return &warehouseUsecase{repo, notifRepo, salesRepo, soRepo, db}
}


func (u *warehouseUsecase) GetInventory(branchID uuid.UUID) ([]domain.WarehouseStock, error) {
	return u.repo.GetStocksByBranchID(branchID)
}

func (u *warehouseUsecase) GetPendingShipments(branchID uuid.UUID) ([]domain.ProductTransfer, error) {
	return u.repo.GetPendingTransfers(branchID)
}

func (u *warehouseUsecase) ReceiveShipment(transferID uuid.UUID, actualQty, damagedQty int) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewWarehouseRepository(tx)

		transfer, err := repo.GetTransferByID(transferID)
		if err != nil {
			return err
		}
		if transfer.Status != "SHIPPED" && transfer.Status != "ARRIVED" {
			return errors.New("shipment is not in SHIPPED or ARRIVED status")
		}

		// If both are 0, assume full receive (legacy or quick scan support)
		if actualQty == 0 && damagedQty == 0 {
			actualQty = transfer.Quantity
		}

		batchNo := transfer.BatchNo
		if batchNo == "" {
			batchNo = "DEFAULT"
		}

		// Update GOOD stock with actual received quantity
		if actualQty > 0 {
			// Convert to total pieces for stock update
			totalPieces := actualQty * transfer.PcsPerUnit
			stock, err := repo.GetStock(transfer.ToBranchID, transfer.ProductID, "GOOD", batchNo)
			if err != nil {
				return err
			}
			stock.Quantity += totalPieces
			stock.ExpiryDate = transfer.ExpiryDate
			if err := repo.UpdateStock(stock); err != nil {
				return err
			}

			// Log GOOD movement
			log := &domain.WarehouseLog{
				BranchID:  transfer.ToBranchID,
				ProductID: transfer.ProductID,
				Type:      "IN",
				Source:    "FACTORY_TRANSFER (GOOD)",
				Quantity:  actualQty * transfer.PcsPerUnit,
			}
			if err := repo.CreateLog(log); err != nil {
				return err
			}
		}

		// Update QUARANTINE stock with damaged quantity
		if damagedQty > 0 {
			// Convert to total pieces for damaged stock update
			totalDamagedPieces := damagedQty * transfer.PcsPerUnit
			damagedStock, err := repo.GetStock(transfer.ToBranchID, transfer.ProductID, "QUARANTINE", batchNo)
			if err != nil {
				return err
			}
			damagedStock.Quantity += totalDamagedPieces
			damagedStock.ExpiryDate = transfer.ExpiryDate
			if err := repo.UpdateStock(damagedStock); err != nil {
				return err
			}

			// Log DAMAGED movement
			log := &domain.WarehouseLog{
				BranchID:  transfer.ToBranchID,
				ProductID: transfer.ProductID,
				Type:      "IN",
				Source:    "FACTORY_TRANSFER (DAMAGED)",
				Quantity:  damagedQty * transfer.PcsPerUnit,
			}
			if err := repo.CreateLog(log); err != nil {
				return err
			}
		}

		transfer.Status = "RECEIVED"
		now := time.Now()
		transfer.ReceivedAt = &now
		transfer.ActualReceivedQuantity = actualQty
		transfer.DamagedQuantity = damagedQty
		
		if err := repo.UpdateTransfer(transfer); err != nil {
			return err
		}

		// Trigger Auto-Fulfillment only for GOOD stock
		if actualQty > 0 {
			return u.internalRunAutoFulfillment(tx, transfer.ToBranchID, transfer.ProductID)
		}
		return nil
	})
}

func (u *warehouseUsecase) internalRunAutoFulfillment(tx *gorm.DB, branchID, productID uuid.UUID) error {
	soRepo := repository.NewSalesOrderRepository(tx)
	wRepo := repository.NewWarehouseRepository(tx)

	// 1. Ambil semua batch yang punya stok tersedia (FEFO)
	availableBatches, err := wRepo.GetAvailableBatches(branchID, productID, "GOOD")
	if err != nil {
		return err
	}

	// 2. Cari semua rincian reservasi BACKORDER untuk produk ini
	var backorderReservations []domain.SalesOrderItemBatch
	if err := tx.Joins("JOIN sales_order_items ON sales_order_items.id = sales_order_item_batches.sales_order_item_id").
		Joins("JOIN sales_orders ON sales_orders.id = sales_order_items.sales_order_id").
		Where("sales_order_items.product_id = ? AND sales_order_item_batches.batch_no = 'BACKORDER' AND sales_order_item_batches.quantity > 0", productID).
		Where("sales_orders.branch_id = ?", branchID).
		Order("sales_orders.created_at ASC").
		Find(&backorderReservations).Error; err != nil {
		return err
	}

	// 3. Alokasikan stok baru ke reservasi BACKORDER (FIFO)
	for i := range backorderReservations {
		res := &backorderReservations[i]
		
		for _, b := range availableBatches {
			availableInBatch := b.Quantity - b.ReservedQuantity
			if availableInBatch <= 0 {
				continue
			}

			moveQty := res.Quantity
			if availableInBatch < moveQty {
				moveQty = availableInBatch
			}

			// Pindahkan reservasi:
			// a. Kurangi dari BACKORDER
			if err := wRepo.ReleaseStock(branchID, productID, "BACKORDER", moveQty); err != nil {
				return err
			}
			// b. Tambah ke Batch Riil
			if err := wRepo.ReserveStock(branchID, productID, b.BatchNo, moveQty); err != nil {
				return err
			}

			// c. Update/Split rincian batch di SO Item
			res.Quantity -= moveQty
			if res.Quantity == 0 {
				tx.Delete(res)
			} else {
				tx.Save(res)
			}

			// Tambah rincian batch baru
			newRes := &domain.SalesOrderItemBatch{
				SalesOrderItemID: res.SalesOrderItemID,
				BatchNo:          b.BatchNo,
				Quantity:         moveQty,
			}
			tx.Create(newRes)

			// Update total available in batch for next iteration
			b.ReservedQuantity += moveQty
			if res.Quantity <= 0 {
				break
			}
		}
	}

	// 4. Cek apakah ada SO yang sekarang sudah fully fulfilled
	orders, err := soRepo.FindWaitingStockByProduct(branchID, productID)
	if err != nil {
		return err
	}

	for _, so := range orders {
		allFulfilled := true
		for _, item := range so.Items {
			// Check if there's any BACKORDER batch left for this item
			var boCount int64
			tx.Model(&domain.SalesOrderItemBatch{}).Where("sales_order_item_id = ? AND batch_no = 'BACKORDER'", item.ID).Count(&boCount)
			if boCount > 0 {
				allFulfilled = false
				break
			}
		}

		if allFulfilled {
			so.Status = domain.SOStatusWaitingWarehouse
			soRepo.Update(&so)
		}
	}

	return nil
}


func (u *warehouseUsecase) GetTransferByDO(doNo string) (*domain.ProductTransfer, error) {
	return u.repo.GetTransferByDO(doNo)
}

func (u *warehouseUsecase) ReceiveShipmentByDO(doNo string, actualQty, damagedQty int) error {
	transfer, err := u.repo.GetTransferByDO(doNo)
	if err != nil {
		return err
	}
	if transfer == nil {
		return errors.New("surat jalan tidak ditemukan")
	}
	return u.ReceiveShipment(transfer.ID, actualQty, damagedQty)
}

func (u *warehouseUsecase) GetWarehouseLogs(branchID uuid.UUID) ([]domain.WarehouseLog, error) {
	return u.repo.GetLogsByBranchID(branchID)
}

func (u *warehouseUsecase) GetAllTransfers(branchID uuid.UUID) ([]domain.ProductTransfer, error) {
	return u.repo.GetTransfersByBranch(branchID)
}

func (u *warehouseUsecase) AdjustStock(branchID, productID uuid.UUID, quantity int, reason string, batchNo string) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewWarehouseRepository(tx)

		stock, err := repo.GetStock(branchID, productID, "GOOD", batchNo)
		if err != nil {
			return err
		}

		diff := quantity - stock.Quantity
		stock.Quantity = quantity
		if err := repo.UpdateStock(stock); err != nil {
			return err
		}

		// Check Threshold
		if stock.Quantity < stock.MinLimit {
			// Trigger Notification
			u.triggerLowStockNotification(stock)
		}

		logType := "IN"
		if diff < 0 {
			logType = "OUT"
		}
		
		absDiff := diff
		if diff < 0 {
			absDiff = -diff
		}

		log := &domain.WarehouseLog{
			BranchID:  branchID,
			ProductID: productID,
			Type:      logType,
			Source:    "OPNAME: " + reason,
			Quantity:  absDiff,
		}
		if err := repo.CreateLog(log); err != nil {
			return err
		}

		// Trigger Auto-Fulfillment if adjustment was positive
		if diff > 0 {
			return u.internalRunAutoFulfillment(tx, branchID, productID)
		}
		return nil
	})
}


func (u *warehouseUsecase) SetStockLimit(branchID, productID uuid.UUID, limit int, batchNo string) error {
	stock, err := u.repo.GetStock(branchID, productID, "GOOD", batchNo)
	if err != nil {
		return err
	}
	stock.MinLimit = limit
	return u.repo.UpdateStock(stock)
}

func (u *warehouseUsecase) ApproveTransfer(transferID uuid.UUID) error {
	transfer, err := u.repo.GetTransferByID(transferID)
	if err != nil {
		return err
	}
	if transfer.Status != "REQUESTED" {
		return errors.New("only REQUESTED transfers can be approved")
	}
	transfer.Status = "APPROVED"
	return u.repo.UpdateTransfer(transfer)
}

func (u *warehouseUsecase) RejectTransfer(transferID uuid.UUID, reason string) error {
	transfer, err := u.repo.GetTransferByID(transferID)
	if err != nil {
		return err
	}
	transfer.Status = "REJECTED"
	transfer.RejectionReason = reason
	return u.repo.UpdateTransfer(transfer)
}

func (u *warehouseUsecase) ConfirmArrival(transferID uuid.UUID) error {
	transfer, err := u.repo.GetTransferByID(transferID)
	if err != nil {
		return err
	}
	if transfer.Status != "SHIPPED" {
		return errors.New("hanya pengiriman berstatus SHIPPED yang bisa dikonfirmasi kedatangannya")
	}
	transfer.Status = "ARRIVED"
	return u.repo.UpdateTransfer(transfer)
}

func (u *warehouseUsecase) ConfirmShipment(transferID uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewFactoryRepository(tx)

		// 1. Get Transfer
		transfer, err := repo.GetTransferByID(transferID)
		if err != nil {
			return err
		}
		if transfer.Status != "APPROVED" {
			return errors.New("hanya pengiriman berstatus APPROVED yang bisa dikonfirmasi pengirimannya")
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
			return fmt.Errorf("stok di pabrik tidak mencukupi untuk pengiriman ini (Butuh: %d, Ada: %d)", totalPieces, stock.Quantity)
		}

		// 3. Reduce Factory Stock
		stock.Quantity -= totalPieces
		if err := repo.UpdateStock(stock); err != nil {
			return err
		}

		// 4. Update Status to SHIPPED
		now := time.Now()
		transfer.Status = "SHIPPED"
		transfer.ShippedAt = &now

		if err := repo.UpdateTransfer(transfer); err != nil {
			return err
		}

		// 5. Create Inventory Log for Factory
		inventoryLog := &domain.FactoryInventoryLog{
			FactoryID: transfer.FromFactoryID,
			ProductID: transfer.ProductID,
			Type:      "OUT",
			Source:    "TRANSFER TO BRANCH (CONFIRMED BY WAREHOUSE)",
			Quantity:  totalPieces,
		}
		return repo.CreateInventoryLog(inventoryLog)
	})
}

func (u *warehouseUsecase) triggerLowStockNotification(stock *domain.WarehouseStock) {
	// Re-fetch with product details for message
	fullStock, err := u.repo.GetStock(stock.BranchID, stock.ProductID, "GOOD", stock.BatchNo)
	if err != nil || fullStock.Branch == nil || fullStock.Branch.CompanyID == nil || fullStock.Product == nil {
		return
	}

	notif := &domain.Notification{
		CompanyID: *fullStock.Branch.CompanyID,
		BranchID:  &stock.BranchID,
		Title:     "Stok Rendah!",
		Message:   fmt.Sprintf("Stok produk %s di bawah limit (%d < %d)", fullStock.Product.Name, fullStock.Quantity, fullStock.MinLimit),
		Type:      "LOW_STOCK",
	}
	_ = u.notifRepo.Create(notif)
}

func (u *warehouseUsecase) DispatchByInvoice(receiptNo string, branchID uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		warehouseRepo := repository.NewWarehouseRepository(tx)
		salesRepo := repository.NewSalesTransactionRepository(tx)

		// 1. Find Transaction
		transaction, err := salesRepo.FindByReceiptNo(receiptNo)
		if err != nil {
			return err
		}
		if transaction == nil {
			return errors.New("nota tidak ditemukan")
		}

		// 2. Validate status
		if transaction.Status == "DELIVERED" {
			return errors.New("transaksi ini sudah selesai dikirim (Status: DELIVERED)")
		}

		// 3. Deduct Stock for each item using reserved batches
		for _, item := range transaction.Items {
			// Find batches reserved for this item
			var reservedBatches []domain.SalesOrderItemBatch
			if err := tx.Where("sales_order_item_id = ?", item.ID).Find(&reservedBatches).Error; err != nil {
				return err
			}

			if len(reservedBatches) == 0 {
				// Fallback if no batch reservation found (should not happen for new orders)
				return fmt.Errorf("tidak ada reservasi batch untuk produk %s", item.Product.Name)
			}

			for _, rb := range reservedBatches {
				stock, err := warehouseRepo.GetStock(branchID, item.ProductID, "GOOD", rb.BatchNo)
				if err != nil {
					return err
				}

				if stock.Quantity < rb.Quantity {
					return fmt.Errorf("stok batch %s tidak mencukupi (Stok: %d, Butuh: %d)", rb.BatchNo, stock.Quantity, rb.Quantity)
				}

				stock.Quantity -= rb.Quantity
				stock.ReservedQuantity -= rb.Quantity
				if err := warehouseRepo.UpdateStock(stock); err != nil {
					return err
				}

				// Log movement per batch
				log := &domain.WarehouseLog{
					BranchID:  branchID,
					ProductID: item.ProductID,
					Type:      "OUT",
					Source:    "SALES_DISPATCH: " + receiptNo + " (Batch: " + rb.BatchNo + ")",
					Quantity:  rb.Quantity,
				}
				if err := warehouseRepo.CreateLog(log); err != nil {
					return err
				}
			}
		}

		// 4. Update Transaction Status
		transaction.Status = "DELIVERED"
		if err := salesRepo.Update(transaction); err != nil {
			return err
		}

		return nil
	})
}

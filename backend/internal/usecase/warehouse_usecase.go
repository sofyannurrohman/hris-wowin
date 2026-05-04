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
	ReceiveShipment(transferID uuid.UUID) error
	GetTransferByDO(doNo string) (*domain.ProductTransfer, error)
	ReceiveShipmentByDO(doNo string) error
	GetWarehouseLogs(branchID uuid.UUID) ([]domain.WarehouseLog, error)
	AdjustStock(branchID, productID uuid.UUID, quantity int, reason string) error
	
	// New Advanced Features
	SetStockLimit(branchID, productID uuid.UUID, limit int) error
	ApproveTransfer(transferID uuid.UUID) error
	RejectTransfer(transferID uuid.UUID) error
}

type warehouseUsecase struct {
	repo     repository.WarehouseRepository
	notifRepo repository.NotificationRepository
	db       *gorm.DB
}

func NewWarehouseUsecase(repo repository.WarehouseRepository, notifRepo repository.NotificationRepository, db *gorm.DB) WarehouseUsecase {
	return &warehouseUsecase{repo, notifRepo, db}
}

func (u *warehouseUsecase) GetInventory(branchID uuid.UUID) ([]domain.WarehouseStock, error) {
	return u.repo.GetStocksByBranchID(branchID)
}

func (u *warehouseUsecase) GetPendingShipments(branchID uuid.UUID) ([]domain.ProductTransfer, error) {
	return u.repo.GetPendingTransfers(branchID)
}

func (u *warehouseUsecase) ReceiveShipment(transferID uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewWarehouseRepository(tx)

		transfer, err := repo.GetTransferByID(transferID)
		if err != nil {
			return err
		}
		if transfer.Status != "SHIPPED" {
			return errors.New("shipment is not in SHIPPED status")
		}

		stock, err := repo.GetStock(transfer.ToBranchID, transfer.ProductID)
		if err != nil {
			return err
		}
		stock.Quantity += transfer.Quantity
		if err := repo.UpdateStock(stock); err != nil {
			return err
		}

		transfer.Status = "RECEIVED"
		now := time.Now()
		transfer.ReceivedAt = &now
		
		if err := repo.UpdateTransfer(transfer); err != nil {
			return err
		}

		log := &domain.WarehouseLog{
			BranchID:  transfer.ToBranchID,
			ProductID: transfer.ProductID,
			Type:      "IN",
			Source:    "FACTORY_TRANSFER",
			Quantity:  transfer.Quantity,
		}
		return repo.CreateLog(log)
	})
}

func (u *warehouseUsecase) GetTransferByDO(doNo string) (*domain.ProductTransfer, error) {
	return u.repo.GetTransferByDO(doNo)
}

func (u *warehouseUsecase) ReceiveShipmentByDO(doNo string) error {
	transfer, err := u.repo.GetTransferByDO(doNo)
	if err != nil {
		return err
	}
	if transfer == nil {
		return errors.New("surat jalan tidak ditemukan")
	}
	return u.ReceiveShipment(transfer.ID)
}

func (u *warehouseUsecase) GetWarehouseLogs(branchID uuid.UUID) ([]domain.WarehouseLog, error) {
	return u.repo.GetLogsByBranchID(branchID)
}

func (u *warehouseUsecase) AdjustStock(branchID, productID uuid.UUID, quantity int, reason string) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewWarehouseRepository(tx)

		stock, err := repo.GetStock(branchID, productID)
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
		return repo.CreateLog(log)
	})
}

func (u *warehouseUsecase) SetStockLimit(branchID, productID uuid.UUID, limit int) error {
	stock, err := u.repo.GetStock(branchID, productID)
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

func (u *warehouseUsecase) RejectTransfer(transferID uuid.UUID) error {
	transfer, err := u.repo.GetTransferByID(transferID)
	if err != nil {
		return err
	}
	transfer.Status = "REJECTED"
	return u.repo.UpdateTransfer(transfer)
}

func (u *warehouseUsecase) triggerLowStockNotification(stock *domain.WarehouseStock) {
	// Re-fetch with product details for message
	fullStock, err := u.repo.GetStock(stock.BranchID, stock.ProductID)
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

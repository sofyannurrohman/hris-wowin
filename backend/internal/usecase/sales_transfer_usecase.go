package usecase

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"gorm.io/gorm"
)

type SalesTransferUsecase interface {
	CreateTransfer(branchID uuid.UUID, req CreateSalesTransferRequest) error
	CompleteTransfer(transferID uuid.UUID) error
	CancelTransfer(transferID uuid.UUID) error
	GetTransfersByBranch(branchID uuid.UUID) ([]domain.SalesTransfer, error)
	GetTransfersByCompany(companyID uuid.UUID) ([]domain.SalesTransfer, error)
	GetSalesStock(employeeID uuid.UUID) ([]domain.SalesStock, error)
	DeleteTransfer(id uuid.UUID) error
}

type salesTransferUsecase struct {
	repo          repository.SalesTransferRepository
	warehouseRepo repository.WarehouseRepository
	db            *gorm.DB
}

func NewSalesTransferUsecase(repo repository.SalesTransferRepository, warehouseRepo repository.WarehouseRepository, db *gorm.DB) SalesTransferUsecase {
	return &salesTransferUsecase{repo, warehouseRepo, db}
}

type CreateSalesTransferRequest struct {
	EmployeeID uuid.UUID              `json:"employee_id" binding:"required"`
	ProductID  uuid.UUID              `json:"product_id" binding:"required"`
	Quantity   int                    `json:"quantity" binding:"required"`
	Type       domain.SalesTransferType `json:"type" binding:"required"`
	Notes      string                 `json:"notes"`
}

func (u *salesTransferUsecase) CreateTransfer(branchID uuid.UUID, req CreateSalesTransferRequest) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewSalesTransferRepository(tx)
		wRepo := repository.NewWarehouseRepository(tx)

		// 1. Validate quantity if it's a TRANSFER (Warehouse -> Salesman)
		if req.Type == domain.SalesTransferOut {
			wStock, err := wRepo.GetStock(branchID, req.ProductID)
			if err != nil {
				return err
			}
			if wStock.Quantity < req.Quantity {
				return errors.New("stok gudang tidak mencukupi")
			}
		} else if req.Type == domain.SalesTransferIn {
			// 2. Validate quantity if it's a RETURN (Salesman -> Warehouse)
			sStock, err := repo.GetSalesStock(req.EmployeeID, req.ProductID)
			if err != nil {
				return err
			}
			if sStock.Quantity < req.Quantity {
				return errors.New("stok sales tidak mencukupi untuk retur")
			}
		}

		transfer := &domain.SalesTransfer{
			BranchID:     branchID,
			EmployeeID:   req.EmployeeID,
			ProductID:    req.ProductID,
			Quantity:     req.Quantity,
			Type:         req.Type,
			Status:       domain.SalesTransferPending,
			Notes:        req.Notes,
			TransferDate: time.Now(),
		}

		return repo.CreateTransfer(transfer)
	})
}

func (u *salesTransferUsecase) CompleteTransfer(transferID uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewSalesTransferRepository(tx)
		wRepo := repository.NewWarehouseRepository(tx)

		transfer, err := repo.GetTransferByID(transferID)
		if err != nil {
			return err
		}

		if transfer.Status != domain.SalesTransferPending {
			return errors.New("transfer is not in pending status")
		}

		if transfer.Type == domain.SalesTransferOut {
			// Warehouse -> Salesman
			// Decrease Warehouse
			wStock, err := wRepo.GetStock(transfer.BranchID, transfer.ProductID)
			if err != nil {
				return err
			}
			wStock.Quantity -= transfer.Quantity
			if err := wRepo.UpdateStock(wStock); err != nil {
				return err
			}

			// Increase Salesman
			sStock, err := repo.GetSalesStock(transfer.EmployeeID, transfer.ProductID)
			if err != nil {
				return err
			}
			sStock.Quantity += transfer.Quantity
			if err := repo.UpdateSalesStock(sStock); err != nil {
				return err
			}

			// Log Warehouse OUT
			wRepo.CreateLog(&domain.WarehouseLog{
				BranchID:  transfer.BranchID,
				ProductID: transfer.ProductID,
				Type:      "OUT",
				Source:    "SALES_TRANSFER",
				Quantity:  transfer.Quantity,
			})

		} else {
			// Salesman -> Warehouse (RETURN)
			// Decrease Salesman
			sStock, err := repo.GetSalesStock(transfer.EmployeeID, transfer.ProductID)
			if err != nil {
				return err
			}
			sStock.Quantity -= transfer.Quantity
			if err := repo.UpdateSalesStock(sStock); err != nil {
				return err
			}

			// Increase Warehouse
			wStock, err := wRepo.GetStock(transfer.BranchID, transfer.ProductID)
			if err != nil {
				return err
			}
			wStock.Quantity += transfer.Quantity
			if err := wRepo.UpdateStock(wStock); err != nil {
				return err
			}

			// Log Warehouse IN
			wRepo.CreateLog(&domain.WarehouseLog{
				BranchID:  transfer.BranchID,
				ProductID: transfer.ProductID,
				Type:      "IN",
				Source:    "SALES_RETURN",
				Quantity:  transfer.Quantity,
			})
		}

		transfer.Status = domain.SalesTransferCompleted
		return repo.UpdateTransfer(transfer)
	})
}

func (u *salesTransferUsecase) CancelTransfer(transferID uuid.UUID) error {
	repo := u.repo
	transfer, err := repo.GetTransferByID(transferID)
	if err != nil {
		return err
	}
	if transfer.Status != domain.SalesTransferPending {
		return errors.New("only pending transfers can be cancelled")
	}
	transfer.Status = domain.SalesTransferCancelled
	return repo.UpdateTransfer(transfer)
}

func (u *salesTransferUsecase) GetTransfersByBranch(branchID uuid.UUID) ([]domain.SalesTransfer, error) {
	return u.repo.GetTransfersByBranch(branchID)
}

func (u *salesTransferUsecase) GetTransfersByCompany(companyID uuid.UUID) ([]domain.SalesTransfer, error) {
	return u.repo.GetTransfersByCompany(companyID)
}

func (u *salesTransferUsecase) GetSalesStock(employeeID uuid.UUID) ([]domain.SalesStock, error) {
	return u.repo.GetStocksByEmployeeID(employeeID)
}

func (u *salesTransferUsecase) DeleteTransfer(id uuid.UUID) error {
	return u.repo.DeleteTransfer(id)
}

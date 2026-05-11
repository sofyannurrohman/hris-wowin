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

type SalesReturnUsecase interface {
	CreateReturn(req CreateReturnRequest) (*domain.SalesReturn, error)
	ApproveReturn(id uuid.UUID, approvedByID uuid.UUID) error
	GetByBranch(branchID uuid.UUID, status string) ([]domain.SalesReturn, error)
	GetByID(id uuid.UUID) (*domain.SalesReturn, error)
}

type salesReturnUsecase struct {
	returnRepo    repository.SalesReturnRepository
	soRepo        repository.SalesOrderRepository
	salesRepo     repository.SalesTransactionRepository
	warehouseRepo repository.WarehouseRepository
	db            *gorm.DB
}

func NewSalesReturnUsecase(
	returnRepo repository.SalesReturnRepository,
	soRepo repository.SalesOrderRepository,
	salesRepo repository.SalesTransactionRepository,
	warehouseRepo repository.WarehouseRepository,
	db *gorm.DB,
) SalesReturnUsecase {
	return &salesReturnUsecase{returnRepo, soRepo, salesRepo, warehouseRepo, db}
}

type CreateReturnRequest struct {
	SOID       uuid.UUID           `json:"so_id" binding:"required"`
	EmployeeID uuid.UUID           `json:"employee_id"`
	Notes      string              `json:"notes"`
	Items      []ReturnItemRequest `json:"items" binding:"required,min=1"`
}

type ReturnItemRequest struct {
	ProductID uuid.UUID `json:"product_id" binding:"required"`
	Quantity  int       `json:"quantity" binding:"required,min=1"`
	Reason    string    `json:"reason"`
	Condition string    `json:"condition"` // 'GOOD', 'DAMAGED'
}

func (u *salesReturnUsecase) CreateReturn(req CreateReturnRequest) (*domain.SalesReturn, error) {
	so, err := u.soRepo.FindByID(req.SOID)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	count, _ := u.returnRepo.CountByBranchAndDate(so.BranchID, now)
	returnNo := repository.GenerateReturnNumber(so.BranchID, now, count)

	ret := &domain.SalesReturn{
		ReturnNo:      returnNo,
		SalesOrderID:  so.ID,
		TransactionID: so.InvoiceID,
		BranchID:      so.BranchID,
		EmployeeID:    req.EmployeeID,
		Status:        domain.ReturnStatusPending,
		Notes:         req.Notes,
	}

	var totalAmount float64
	for _, item := range req.Items {
		// Cari harga dari SO items
		var price float64
		for _, soItem := range so.Items {
			if soItem.ProductID == item.ProductID {
				price = soItem.Price
				break
			}
		}

		ret.Items = append(ret.Items, domain.SalesReturnItem{
			ProductID: item.ProductID,
			Quantity:  item.Quantity,
			Price:     price,
			Reason:    item.Reason,
			Condition: item.Condition,
		})
		totalAmount += float64(item.Quantity) * price
	}
	ret.TotalAmount = totalAmount

	if err := u.returnRepo.Create(ret); err != nil {
		return nil, err
	}
	return u.returnRepo.FindByID(ret.ID)
}

func (u *salesReturnUsecase) ApproveReturn(id uuid.UUID, approvedByID uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		returnRepo := repository.NewSalesReturnRepository(tx)
		wRepo := repository.NewWarehouseRepository(tx)
		salesRepo := repository.NewSalesTransactionRepository(tx)

		ret, err := returnRepo.FindByID(id)
		if err != nil {
			return err
		}
		if ret.Status != domain.ReturnStatusPending {
			return errors.New("hanya retur status PENDING yang bisa disetujui")
		}

		// 1. Masukkan barang ke Gudang Karantina
		for _, item := range ret.Items {
			stock, err := wRepo.GetStock(ret.BranchID, item.ProductID, "QUARANTINE", "DEFAULT")
			if err != nil {
				return err
			}
			stock.Quantity += item.Quantity
			if err := wRepo.UpdateStock(stock); err != nil {
				return err
			}

			// Log mutasi karantina
			wRepo.CreateLog(&domain.WarehouseLog{
				BranchID:  ret.BranchID,
				ProductID: item.ProductID,
				Type:      "IN",
				Source:    "RETUR: " + ret.ReturnNo,
				Quantity:  item.Quantity,
			})
		}

		// 2. Jika ada Invoice, potong nominal Tagihan (Credit Note)
		if ret.TransactionID != nil {
			inv, err := salesRepo.FindByID(*ret.TransactionID)
			if err == nil && inv != nil {
				inv.TotalAmount -= ret.TotalAmount
				// Tambahkan catatan nota kredit ke notes invoice
				newNotes := ""
				if inv.Notes != nil {
					newNotes = *inv.Notes + "\n"
				}
				newNotes += fmt.Sprintf("[KREDIT NOTA: %s senilai %v]", ret.ReturnNo, ret.TotalAmount)
				inv.Notes = &newNotes
				
				if err := salesRepo.Update(inv); err != nil {
					return err
				}
			}
		}

		now := time.Now()
		ret.Status = domain.ReturnStatusApproved
		ret.ApprovedAt = &now
		ret.ApprovedByID = &approvedByID
		return returnRepo.Update(ret)
	})
}

func (u *salesReturnUsecase) GetByBranch(branchID uuid.UUID, status string) ([]domain.SalesReturn, error) {
	return u.returnRepo.FindByBranch(branchID, status)
}

func (u *salesReturnUsecase) GetByID(id uuid.UUID) (*domain.SalesReturn, error) {
	return u.returnRepo.FindByID(id)
}

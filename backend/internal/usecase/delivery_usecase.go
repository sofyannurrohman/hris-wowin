package usecase

import (
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"gorm.io/gorm"
)

type DeliveryUsecase interface {
	CreateBatch(req CreateBatchRequest) (*domain.DeliveryBatch, error)
	SupervisorApproveBatch(batchID uuid.UUID, supervisorID uuid.UUID) error
	ApproveBatch(batchID uuid.UUID, adminID uuid.UUID) error
	AssignArmada(batchID uuid.UUID, driverID uuid.UUID, vehicleID uuid.UUID, supervisorID uuid.UUID) error
	StartDelivery(doNo string) error
	ConfirmItemDelivery(itemID uuid.UUID, status domain.DeliveryItemStatus, notes string) error
	GetDriverTasks(driverID uuid.UUID) ([]domain.DeliveryBatch, error)
	GetDriverHistory(driverID uuid.UUID) ([]domain.DeliveryBatch, error)
	GetBatchDetail(doNo string) (*domain.DeliveryBatch, error)
	GetBatchByID(id uuid.UUID) (*domain.DeliveryBatch, error)
	UpdateBatchItems(batchID uuid.UUID, req CreateBatchRequest) error
	ConfirmItemByReceipt(receiptNo string, notes string) error
	UpdateBatchCash(batchID uuid.UUID, amount float64) error
	ListBatches() ([]domain.DeliveryBatch, error)
	DeleteBatch(id uuid.UUID) error
}

type CreateBatchRequest struct {
	CompanyID    uuid.UUID   `json:"company_id"`
	BranchID     *uuid.UUID  `json:"branch_id"`
	DriverID     *uuid.UUID  `json:"driver_id"`
	VehicleID    *uuid.UUID  `json:"vehicle_id"`
	SalesOrderIDs []uuid.UUID `json:"sales_order_ids"`

	// Legacy — dipertahankan agar tidak break frontend lama
	SalesTrxIDs []uuid.UUID `json:"sales_transaction_ids"`
}

type deliveryUsecase struct {
	repo          repository.DeliveryRepository
	salesRepo     repository.SalesTransactionRepository
	soRepo        repository.SalesOrderRepository
	warehouseRepo repository.WarehouseRepository
	db            *gorm.DB
}

func NewDeliveryUsecase(
	repo repository.DeliveryRepository,
	salesRepo repository.SalesTransactionRepository,
	soRepo repository.SalesOrderRepository,
	warehouseRepo repository.WarehouseRepository,
	db *gorm.DB,
) DeliveryUsecase {
	return &deliveryUsecase{repo, salesRepo, soRepo, warehouseRepo, db}
}

func (u *deliveryUsecase) CreateBatch(req CreateBatchRequest) (*domain.DeliveryBatch, error) {
	now := time.Now()
	// Generate nomor Surat Jalan saat batch dibuat (bukan saat di-approve)
	doNo := fmt.Sprintf("SJ-%s-%s", now.Format("20060102"), uuid.New().String()[:6])

	batch := &domain.DeliveryBatch{
		CompanyID:       req.CompanyID,
		BranchID:        req.BranchID,
		DriverID:        req.DriverID,
		VehicleID:       req.VehicleID,
		DeliveryOrderNo: &doNo,
		BarcodeData:     doNo, // QR akan di-generate dari field ini di frontend
		Status:          domain.DeliveryBatchWaitingApproval,
	}

	// Tambahkan SO ke dalam batch (alur baru)
	for i, soID := range req.SalesOrderIDs {
		batch.Items = append(batch.Items, domain.DeliveryItem{
			SalesOrderID: soID,
			BarcodeData:  soID.String(), // Tiap nota punya barcode sendiri
			Sequence:     i + 1,
			Status:       domain.DeliveryItemPending,
		})
	}

	// Legacy: tambahkan SalesTransaction ke batch (backward-compatibility)
	for i, trxID := range req.SalesTrxIDs {
		trxIDCopy := trxID
		batch.Items = append(batch.Items, domain.DeliveryItem{
			SalesTransactionID: &trxIDCopy,
			Sequence:           len(req.SalesOrderIDs) + i + 1,
			Status:             domain.DeliveryItemPending,
		})
	}

	if err := u.repo.CreateBatch(batch); err != nil {
		return nil, err
	}

	// Update status setiap SO menjadi IN_DELIVERY
	for _, soID := range req.SalesOrderIDs {
		so, err := u.soRepo.FindByID(soID)
		if err != nil || so == nil {
			continue
		}
		batchID := batch.ID
		so.Status = domain.SOStatusInDelivery
		so.DeliveryBatchID = &batchID
		so.DeliveryOrderNo = &doNo
		_ = u.soRepo.Update(so)
	}

	return batch, nil
}

func (u *deliveryUsecase) SupervisorApproveBatch(batchID uuid.UUID, supervisorID uuid.UUID) error {
	batch, err := u.repo.GetBatchByID(batchID)
	if err != nil {
		return err
	}

	if batch.Status != domain.DeliveryBatchWaitingApproval {
		return errors.New("batch tidak dalam status menunggu persetujuan supervisor")
	}

	batch.Status = domain.DeliveryBatchSupervisorApproved
	batch.SupervisorID = &supervisorID
	now := time.Now()
	batch.AssignedAt = &now

	return u.repo.UpdateBatch(batch)
}

func (u *deliveryUsecase) ApproveBatch(batchID uuid.UUID, adminID uuid.UUID) error {
	batch, err := u.repo.GetBatchByID(batchID)
	if err != nil {
		return err
	}

	if batch.Status != domain.DeliveryBatchSupervisorApproved {
		return errors.New("surat jalan belum disetujui oleh supervisor")
	}

	now := time.Now()
	batch.Status = domain.DeliveryBatchPending
	
	// Generate DO Number
	doNo := fmt.Sprintf("SJ-%s-%s", now.Format("20060102"), uuid.New().String()[:6])
	batch.DeliveryOrderNo = &doNo
	
	batch.AdminNotaID = &adminID
	batch.ApprovedAt = &now

	return u.repo.UpdateBatch(batch)
}

func (u *deliveryUsecase) AssignArmada(batchID uuid.UUID, driverID uuid.UUID, vehicleID uuid.UUID, supervisorID uuid.UUID) error {
	batch, err := u.repo.GetBatchByID(batchID)
	if err != nil {
		return err
	}

	// Allow revision if status is WAITING_ASSIGNMENT or PENDING
	if batch.Status != domain.DeliveryBatchWaitingAssignment && batch.Status != domain.DeliveryBatchPending {
		return errors.New("surat jalan tidak dalam status yang bisa ditugaskan atau direvisi armada")
	}

	now := time.Now()
	
	// Only generate DO number and change status if it's the first assignment
	if batch.Status == domain.DeliveryBatchWaitingAssignment {
		doNo := fmt.Sprintf("SJ-%s-%s", now.Format("20060102"), uuid.New().String()[:6])
		batch.Status = domain.DeliveryBatchPending
		batch.DeliveryOrderNo = &doNo
	}

	batch.DriverID = &driverID
	batch.VehicleID = &vehicleID
	batch.SupervisorID = &supervisorID
	batch.AssignedAt = &now

	return u.repo.UpdateBatch(batch)
}

func (u *deliveryUsecase) StartDelivery(doNo string) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		repo := repository.NewDeliveryRepository(tx)
		wRepo := repository.NewWarehouseRepository(tx)

		batch, err := repo.GetBatchByDO(doNo)
		if err != nil {
			return err
		}

		if batch.Status != domain.DeliveryBatchPending {
			return errors.New("pengiriman sudah dimulai atau selesai")
		}

		now := time.Now()
		batch.Status = domain.DeliveryBatchOnDelivery
		batch.StartedAt = &now

		// 1. Update status batch ke ON_DELIVERY
		if err := repo.UpdateBatch(batch); err != nil {
			return err
		}

		// 2. Potong Stok Gudang secara otomatis
		if batch.BranchID == nil {
			return errors.New("branch_id tidak ditemukan dalam batch")
		}

		for _, di := range batch.Items {
			if di.SalesOrder == nil {
				continue
			}

			for _, soi := range di.SalesOrder.Items {
				// Gunakan data batch yang ter-reserve untuk pemotongan stok yang akurat
				for _, b := range soi.Batches {
					if b.Quantity <= 0 {
						continue
					}

					stock, err := wRepo.GetStock(*batch.BranchID, soi.ProductID, "GOOD", b.BatchNo)
					if err != nil {
						return err
					}

					// Kurangi stok fisik
					stock.Quantity -= b.Quantity
					if stock.Quantity < 0 {
						stock.Quantity = 0
					}

					// Kurangi reserved quantity
					if stock.ReservedQuantity >= b.Quantity {
						stock.ReservedQuantity -= b.Quantity
					} else {
						stock.ReservedQuantity = 0
					}

					if err := wRepo.UpdateStock(stock); err != nil {
						return err
					}

					// Catat log mutasi barang keluar
					wRepo.CreateLog(&domain.WarehouseLog{
						BranchID:  *batch.BranchID,
						ProductID: soi.ProductID,
						Type:      "OUT",
						Source:    fmt.Sprintf("KIRIM: %s", doNo),
						Quantity:  b.Quantity,
						BatchNo:   b.BatchNo,
					})
				}
			}
		}

		return nil
	})
}

func (u *deliveryUsecase) ConfirmItemDelivery(itemID uuid.UUID, status domain.DeliveryItemStatus, notes string) error {
	// Ambil detail item untuk cek status batch
	// Catatan: Karena itemRepo tidak punya FindByID langsung, kita gunakan repo.GetBatchByID jika perlu,
	// namun di sini kita asumsikan itemID valid. Untuk keamanan extra, kita bisa menambah method GetItemByID.
	// Namun sementara kita percayakan pada filtering GetDriverTasks yang sudah kita perketat.
	
	now := time.Now()
	item := &domain.DeliveryItem{
		ID:          itemID,
		Status:      status,
		Notes:       notes,
		DeliveredAt: &now,
	}

	return u.repo.UpdateItem(item)
}

func (u *deliveryUsecase) ConfirmItemByReceipt(receiptNo string, notes string) error {
	item, err := u.repo.GetItemByReceiptNo(receiptNo)
	if err != nil {
		return err
	}

	if item.Status == domain.DeliveryItemDelivered {
		return errors.New("barang sudah ditandai sebagai terkirim")
	}

	// Verifikasi status batch
	batch, err := u.repo.GetBatchByID(item.DeliveryBatchID)
	if err == nil && batch.Status == domain.DeliveryBatchWaitingApproval {
		return errors.New("tidak bisa konfirmasi item pada batch yang belum disetujui")
	}

	now := time.Now()
	item.Status = domain.DeliveryItemDelivered
	item.Notes = notes
	item.DeliveredAt = &now

	return u.repo.UpdateItem(item)
}

func (u *deliveryUsecase) UpdateBatchCash(batchID uuid.UUID, amount float64) error {
	batch, err := u.repo.GetBatchByID(batchID)
	if err != nil {
		return err
	}

	batch.TotalCashCollected = amount
	return u.repo.UpdateBatch(batch)
}

func (u *deliveryUsecase) GetDriverTasks(driverID uuid.UUID) ([]domain.DeliveryBatch, error) {
	return u.repo.GetBatchesByDriver(driverID)
}

func (u *deliveryUsecase) GetDriverHistory(driverID uuid.UUID) ([]domain.DeliveryBatch, error) {
	return u.repo.GetBatchesHistoryByDriver(driverID)
}

func (u *deliveryUsecase) GetBatchDetail(doNo string) (*domain.DeliveryBatch, error) {
	return u.repo.GetBatchByDO(doNo)
}

func (u *deliveryUsecase) GetBatchByID(id uuid.UUID) (*domain.DeliveryBatch, error) {
	return u.repo.GetBatchByID(id)
}

func (u *deliveryUsecase) ListBatches() ([]domain.DeliveryBatch, error) {
	return u.repo.ListBatches()
}

func (u *deliveryUsecase) UpdateBatchItems(batchID uuid.UUID, req CreateBatchRequest) error {
	batch, err := u.repo.GetBatchByID(batchID)
	if err != nil {
		return err
	}

	// Hanya izinkan edit jika belum sampai status PENDING atau pengiriman dimulai
	if batch.Status == domain.DeliveryBatchPending || batch.Status == domain.DeliveryBatchOnDelivery || batch.Status == domain.DeliveryBatchCompleted {
		return errors.New("tidak bisa mengedit batch yang sudah disetujui Admin atau sudah selesai")
	}

	// 1. Reset status SO lama menjadi CONFIRMED agar kembali ke antrean
	for _, oldItem := range batch.Items {
		if oldItem.SalesOrderID != uuid.Nil {
			so, err := u.soRepo.FindByID(oldItem.SalesOrderID)
			if err == nil && so != nil {
				so.Status = domain.SOStatusConfirmed
				so.DeliveryBatchID = nil
				so.DeliveryOrderNo = nil
				_ = u.soRepo.Update(so)
			}
		}
	}

	batch.DriverID = req.DriverID
	batch.Driver = nil // Reset association agar GORM mengupdate kolom FK
	batch.VehicleID = req.VehicleID
	batch.Vehicle = nil // Reset association agar GORM mengupdate kolom FK
	
	// Update items: clear existing and add new
	items := make([]domain.DeliveryItem, 0)
	
	// Tambahkan SO ke dalam batch (alur baru)
	for i, soID := range req.SalesOrderIDs {
		soIDCopy := soID
		items = append(items, domain.DeliveryItem{
			DeliveryBatchID: batchID,
			SalesOrderID:    soIDCopy,
			Sequence:        i + 1,
			Status:          domain.DeliveryItemPending,
		})
	}

	// Legacy: tambahkan SalesTransaction ke batch (backward-compatibility)
	for i, trxID := range req.SalesTrxIDs {
		trxIDCopy := trxID
		items = append(items, domain.DeliveryItem{
			DeliveryBatchID:    batchID,
			SalesTransactionID: &trxIDCopy,
			Sequence:           i + 1 + len(req.SalesOrderIDs),
			Status:             domain.DeliveryItemPending,
		})
	}
	batch.Items = items

	if err := u.repo.UpdateBatch(batch); err != nil {
		return err
	}

	// 2. Update status SO baru menjadi IN_DELIVERY
	for _, soID := range req.SalesOrderIDs {
		so, err := u.soRepo.FindByID(soID)
		if err == nil && so != nil {
			batchID := batch.ID
			so.Status = domain.SOStatusInDelivery
			so.DeliveryBatchID = &batchID
			if batch.DeliveryOrderNo != nil {
				so.DeliveryOrderNo = batch.DeliveryOrderNo
			}
			_ = u.soRepo.Update(so)
		}
	}

	return nil
}

func (u *deliveryUsecase) DeleteBatch(id uuid.UUID) error {
	batch, err := u.repo.GetBatchByID(id)
	if err != nil {
		return err
	}

	// Hanya izinkan hapus jika belum sampai status PENDING atau pengiriman dimulai
	if batch.Status == domain.DeliveryBatchPending || batch.Status == domain.DeliveryBatchOnDelivery || batch.Status == domain.DeliveryBatchCompleted {
		return errors.New("tidak bisa menghapus batch yang sudah disetujui Admin atau sedang dalam proses pengiriman")
	}

	// Reset status SO menjadi CONFIRMED agar bisa dibatch lagi
	for _, item := range batch.Items {
		if item.SalesOrderID != uuid.Nil {
			so, err := u.soRepo.FindByID(item.SalesOrderID)
			if err == nil && so != nil {
				so.Status = domain.SOStatusConfirmed
				so.DeliveryBatchID = nil
				so.DeliveryOrderNo = nil
				_ = u.soRepo.Update(so)
			}
		}
	}

	return u.repo.DeleteBatch(id)
}

// Haversine distance for route optimization helper (future use)
func haversine(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371 // Earth radius in km
	dLat := (lat2 - lat1) * (math.Pi / 180)
	dLon := (lon2 - lon1) * (math.Pi / 180)
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*(math.Pi/180))*math.Cos(lat2*(math.Pi/180))*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}

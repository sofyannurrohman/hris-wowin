package usecase

import (
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type DeliveryUsecase interface {
	CreateBatch(req CreateBatchRequest) (*domain.DeliveryBatch, error)
	SupervisorApproveBatch(batchID uuid.UUID, supervisorID uuid.UUID) error
	ApproveBatch(batchID uuid.UUID, adminID uuid.UUID) error
	AssignArmada(batchID uuid.UUID, driverID uuid.UUID, vehicleID uuid.UUID, supervisorID uuid.UUID) error
	StartDelivery(doNo string) error
	ConfirmItemDelivery(itemID uuid.UUID, status domain.DeliveryItemStatus, notes string) error
	GetDriverTasks(driverID uuid.UUID) ([]domain.DeliveryBatch, error)
	GetBatchDetail(doNo string) (*domain.DeliveryBatch, error)
	GetBatchByID(id uuid.UUID) (*domain.DeliveryBatch, error)
	UpdateBatchItems(batchID uuid.UUID, req CreateBatchRequest) error
	ConfirmItemByReceipt(receiptNo string, notes string) error
	UpdateBatchCash(batchID uuid.UUID, amount float64) error
	ListBatches() ([]domain.DeliveryBatch, error)
	DeleteBatch(id uuid.UUID) error
}

type CreateBatchRequest struct {
	CompanyID   uuid.UUID   `json:"company_id"`
	DriverID    *uuid.UUID  `json:"driver_id"`
	VehicleID   *uuid.UUID  `json:"vehicle_id"`
	SalesTrxIDs []uuid.UUID `json:"sales_transaction_ids"`
}

type deliveryUsecase struct {
	repo      repository.DeliveryRepository
	salesRepo repository.SalesTransactionRepository
}

func NewDeliveryUsecase(repo repository.DeliveryRepository, salesRepo repository.SalesTransactionRepository) DeliveryUsecase {
	return &deliveryUsecase{repo, salesRepo}
}

func (u *deliveryUsecase) CreateBatch(req CreateBatchRequest) (*domain.DeliveryBatch, error) {
	batch := &domain.DeliveryBatch{
		CompanyID: req.CompanyID,
		DriverID:  req.DriverID,
		VehicleID: req.VehicleID,
		Status:    domain.DeliveryBatchWaitingApproval,
	}

	for i, trxID := range req.SalesTrxIDs {
		batch.Items = append(batch.Items, domain.DeliveryItem{
			SalesTransactionID: trxID,
			Sequence:           i + 1,
			Status:             domain.DeliveryItemPending,
		})
	}

	if err := u.repo.CreateBatch(batch); err != nil {
		return nil, err
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
	batch, err := u.repo.GetBatchByDO(doNo)
	if err != nil {
		return err
	}

	if batch.Status != domain.DeliveryBatchPending {
		return errors.New("pengiriman sudah dimulai atau selesai")
	}

	now := time.Now()
	batch.Status = domain.DeliveryBatchOnDelivery
	batch.StartedAt = &now

	return u.repo.UpdateBatch(batch)
}

func (u *deliveryUsecase) ConfirmItemDelivery(itemID uuid.UUID, status domain.DeliveryItemStatus, notes string) error {
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

	// Only allow edit if not started/completed
	if batch.Status == domain.DeliveryBatchOnDelivery || batch.Status == domain.DeliveryBatchCompleted {
		return errors.New("tidak bisa mengedit batch yang sedang dikirim atau sudah selesai")
	}

	batch.DriverID = req.DriverID
	batch.VehicleID = req.VehicleID
	
	// Update items: clear existing and add new
	// In GORM we can use association management
	items := make([]domain.DeliveryItem, 0)
	for i, trxID := range req.SalesTrxIDs {
		items = append(items, domain.DeliveryItem{
			DeliveryBatchID:    batchID,
			SalesTransactionID: trxID,
			Sequence:           i + 1,
			Status:             domain.DeliveryItemPending,
		})
	}
	batch.Items = items

	return u.repo.UpdateBatch(batch)
}

func (u *deliveryUsecase) DeleteBatch(id uuid.UUID) error {
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

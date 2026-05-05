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
	ApproveBatch(batchID uuid.UUID, adminID uuid.UUID) error
	AssignArmada(batchID uuid.UUID, driverID uuid.UUID, vehicleID uuid.UUID, supervisorID uuid.UUID) error
	StartDelivery(doNo string) error
	ConfirmItemDelivery(itemID uuid.UUID, status domain.DeliveryItemStatus, notes string) error
	GetDriverTasks(driverID uuid.UUID) ([]domain.DeliveryBatch, error)
	GetBatchDetail(doNo string) (*domain.DeliveryBatch, error)
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

func (u *deliveryUsecase) ApproveBatch(batchID uuid.UUID, adminID uuid.UUID) error {
	batch, err := u.repo.GetBatchByID(batchID)
	if err != nil {
		return err
	}

	if batch.Status != domain.DeliveryBatchWaitingApproval {
		return errors.New("surat jalan tidak dalam status menunggu persetujuan")
	}

	now := time.Now()
	batch.Status = domain.DeliveryBatchWaitingAssignment
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
	// Simple implementation: update item status
	// In real world, we might want to check if the whole batch is finished
	now := time.Now()
	item := &domain.DeliveryItem{
		ID:          itemID,
		Status:      status,
		Notes:       notes,
		DeliveredAt: &now,
	}

	return u.repo.UpdateItem(item)
}

func (u *deliveryUsecase) GetDriverTasks(driverID uuid.UUID) ([]domain.DeliveryBatch, error) {
	return u.repo.GetBatchesByDriver(driverID)
}

func (u *deliveryUsecase) GetBatchDetail(doNo string) (*domain.DeliveryBatch, error) {
	return u.repo.GetBatchByDO(doNo)
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

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
	StartDelivery(doNo string) error
	ConfirmItemDelivery(itemID uuid.UUID, status domain.DeliveryItemStatus, notes string) error
	GetDriverTasks(driverID uuid.UUID) ([]domain.DeliveryBatch, error)
	GetBatchDetail(doNo string) (*domain.DeliveryBatch, error)
}

type CreateBatchRequest struct {
	CompanyID   uuid.UUID   `json:"company_id"`
	DriverID    uuid.UUID   `json:"driver_id"`
	VehicleID   uuid.UUID   `json:"vehicle_id"`
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
	now := time.Now()
	doNo := fmt.Sprintf("SJ-%s-%s", now.Format("20060102"), uuid.New().String()[:6])

	batch := &domain.DeliveryBatch{
		CompanyID:       req.CompanyID,
		DriverID:        req.DriverID,
		VehicleID:       req.VehicleID,
		DeliveryOrderNo: doNo,
		Status:          domain.DeliveryBatchPending,
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

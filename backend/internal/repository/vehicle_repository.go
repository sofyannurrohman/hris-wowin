package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type VehicleRepository interface {
	Create(vehicle *domain.Vehicle) error
	GetAll(companyID uuid.UUID) ([]domain.Vehicle, error)
	GetByID(id uuid.UUID) (*domain.Vehicle, error)
	Update(vehicle *domain.Vehicle) error
	Delete(id uuid.UUID) error
	GetLogs(vehicleID uuid.UUID) ([]domain.DeliveryBatch, error)
}

type vehicleRepository struct {
	db *gorm.DB
}

func NewVehicleRepository(db *gorm.DB) VehicleRepository {
	return &vehicleRepository{db}
}

func (r *vehicleRepository) Create(vehicle *domain.Vehicle) error {
	return r.db.Create(vehicle).Error
}

func (r *vehicleRepository) GetAll(companyID uuid.UUID) ([]domain.Vehicle, error) {
	var vehicles []domain.Vehicle
	err := r.db.Preload("Branch").Where("company_id = ?", companyID).Find(&vehicles).Error
	return vehicles, err
}

func (r *vehicleRepository) GetByID(id uuid.UUID) (*domain.Vehicle, error) {
	var vehicle domain.Vehicle
	err := r.db.Preload("Branch").First(&vehicle, "id = ?", id).Error
	return &vehicle, err
}

func (r *vehicleRepository) Update(vehicle *domain.Vehicle) error {
	return r.db.Save(vehicle).Error
}

func (r *vehicleRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&domain.Vehicle{}, "id = ?", id).Error
}

func (r *vehicleRepository) GetLogs(vehicleID uuid.UUID) ([]domain.DeliveryBatch, error) {
	var logs []domain.DeliveryBatch
	err := r.db.Preload("Driver").
		Preload("Items.SalesTransaction.Store").
		Where("vehicle_id = ?", vehicleID).
		Order("created_at desc").
		Limit(50).
		Find(&logs).Error
	return logs, err
}

package usecase

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type VehicleUsecase interface {
	CreateVehicle(vehicle *domain.Vehicle) error
	GetVehicles(companyID uuid.UUID) ([]domain.Vehicle, error)
	GetVehicleDetail(id uuid.UUID) (*domain.Vehicle, error)
	UpdateVehicle(vehicle *domain.Vehicle) error
	DeleteVehicle(id uuid.UUID) error
}

type vehicleUsecase struct {
	repo repository.VehicleRepository
}

func NewVehicleUsecase(repo repository.VehicleRepository) VehicleUsecase {
	return &vehicleUsecase{repo}
}

func (u *vehicleUsecase) CreateVehicle(vehicle *domain.Vehicle) error {
	return u.repo.Create(vehicle)
}

func (u *vehicleUsecase) GetVehicles(companyID uuid.UUID) ([]domain.Vehicle, error) {
	return u.repo.GetAll(companyID)
}

func (u *vehicleUsecase) GetVehicleDetail(id uuid.UUID) (*domain.Vehicle, error) {
	return u.repo.GetByID(id)
}

func (u *vehicleUsecase) UpdateVehicle(vehicle *domain.Vehicle) error {
	return u.repo.Update(vehicle)
}

func (u *vehicleUsecase) DeleteVehicle(id uuid.UUID) error {
	return u.repo.Delete(id)
}

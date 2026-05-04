package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type StoreRepository interface {
	Create(store *domain.Store) error
	FindAll() ([]domain.Store, error)
	FindByID(id uuid.UUID) (*domain.Store, error)
	Update(store *domain.Store) error
	Delete(id uuid.UUID) error
	FindByVisitDay(day int, employeeID uuid.UUID) ([]domain.Store, error)
}

type storeRepository struct {
	db *gorm.DB
}

func NewStoreRepository(db *gorm.DB) StoreRepository {
	return &storeRepository{db}
}

func (r *storeRepository) Create(store *domain.Store) error {
	return r.db.Create(store).Error
}

func (r *storeRepository) FindAll() ([]domain.Store, error) {
	var stores []domain.Store
	if err := r.db.Preload("Company").Preload("AssignedEmployee").Find(&stores).Error; err != nil {
		return nil, err
	}
	return stores, nil
}

func (r *storeRepository) FindByID(id uuid.UUID) (*domain.Store, error) {
	var store domain.Store
	if err := r.db.Preload("Company").Preload("AssignedEmployee").Where("id = ?", id).First(&store).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &store, nil
}

func (r *storeRepository) Update(store *domain.Store) error {
	return r.db.Save(store).Error
}

func (r *storeRepository) Delete(id uuid.UUID) error {
	return r.db.Where("id = ?", id).Delete(&domain.Store{}).Error
}

func (r *storeRepository) FindByVisitDay(day int, employeeID uuid.UUID) ([]domain.Store, error) {
	var stores []domain.Store
	if err := r.db.Where("? = ANY(visit_days) AND assigned_employee_id = ?", day, employeeID).Find(&stores).Error; err != nil {
		return nil, err
	}
	return stores, nil
}

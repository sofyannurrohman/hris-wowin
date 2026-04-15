package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type ShiftRepository interface {
	Create(shift *domain.Shift) error
	FindAll() ([]domain.Shift, error)
	FindByID(id uuid.UUID) (*domain.Shift, error)
	Update(shift *domain.Shift) error
	Delete(id uuid.UUID) error
}

type shiftRepository struct {
	db *gorm.DB
}

func NewShiftRepository(db *gorm.DB) ShiftRepository {
	return &shiftRepository{db}
}

func (r *shiftRepository) Create(shift *domain.Shift) error {
	return r.db.Create(shift).Error
}

func (r *shiftRepository) FindAll() ([]domain.Shift, error) {
	var shifts []domain.Shift
	if err := r.db.Preload("Branch").Find(&shifts).Error; err != nil {
		return nil, err
	}
	return shifts, nil
}

func (r *shiftRepository) FindByID(id uuid.UUID) (*domain.Shift, error) {
	var shift domain.Shift
	if err := r.db.Preload("Branch").Where("id = ?", id).First(&shift).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &shift, nil
}

func (r *shiftRepository) Update(shift *domain.Shift) error {
	return r.db.Save(shift).Error
}

func (r *shiftRepository) Delete(id uuid.UUID) error {
	return r.db.Where("id = ?", id).Delete(&domain.Shift{}).Error
}

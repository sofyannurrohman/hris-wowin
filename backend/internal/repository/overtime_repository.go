package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type OvertimeRepository interface {
	Create(overtime *domain.Overtime) error
	FindByEmployeeID(employeeID uuid.UUID) ([]domain.Overtime, error)
	FindAll() ([]domain.Overtime, error)
	UpdateStatus(id uuid.UUID, status domain.OvertimeStatus, approvedBy *uuid.UUID, rejectReason *string) error
	FindByID(id uuid.UUID) (*domain.Overtime, error)
	Update(overtime *domain.Overtime) error
	Delete(id uuid.UUID) error
}

type overtimeRepository struct {
	db *gorm.DB
}

func NewOvertimeRepository(db *gorm.DB) OvertimeRepository {
	return &overtimeRepository{db}
}

func (r *overtimeRepository) Create(overtime *domain.Overtime) error {
	return r.db.Create(overtime).Error
}

func (r *overtimeRepository) FindByEmployeeID(employeeID uuid.UUID) ([]domain.Overtime, error) {
	var overtimes []domain.Overtime
	err := r.db.Where("employee_id = ?", employeeID).Order("date desc").Find(&overtimes).Error
	return overtimes, err
}

func (r *overtimeRepository) FindAll() ([]domain.Overtime, error) {
	var overtimes []domain.Overtime
	err := r.db.Preload("Employee").Order("created_at desc").Find(&overtimes).Error
	return overtimes, err
}

func (r *overtimeRepository) UpdateStatus(id uuid.UUID, status domain.OvertimeStatus, approvedBy *uuid.UUID, rejectReason *string) error {
	return r.db.Model(&domain.Overtime{}).Where("id = ?", id).Updates(map[string]interface{}{
		"status":        status,
		"approved_by":   approvedBy,
		"reject_reason": rejectReason,
	}).Error
}

func (r *overtimeRepository) FindByID(id uuid.UUID) (*domain.Overtime, error) {
	var overtime domain.Overtime
	err := r.db.First(&overtime, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &overtime, nil
}

func (r *overtimeRepository) Update(overtime *domain.Overtime) error {
	return r.db.Save(overtime).Error
}

func (r *overtimeRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&domain.Overtime{}, "id = ?", id).Error
}

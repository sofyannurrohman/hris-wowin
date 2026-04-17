package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type ReimbursementRepository interface {
	Create(reimbursement *domain.Reimbursement) error
	GetByID(id uuid.UUID) (*domain.Reimbursement, error)
	GetByEmployeeID(employeeID uuid.UUID, limit, offset int) ([]domain.Reimbursement, error)
	GetAll(status string, limit, offset int) ([]domain.Reimbursement, error)
	Update(reimbursement *domain.Reimbursement) error
	Delete(id uuid.UUID) error
}

type reimbursementRepository struct {
	db *gorm.DB
}

func NewReimbursementRepository(db *gorm.DB) ReimbursementRepository {
	return &reimbursementRepository{db}
}

func (r *reimbursementRepository) Create(reimbursement *domain.Reimbursement) error {
	return r.db.Create(reimbursement).Error
}

func (r *reimbursementRepository) GetByID(id uuid.UUID) (*domain.Reimbursement, error) {
	var reimbursement domain.Reimbursement
	err := r.db.Preload("Employee").Preload("Approver").First(&reimbursement, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &reimbursement, nil
}

func (r *reimbursementRepository) GetByEmployeeID(employeeID uuid.UUID, limit, offset int) ([]domain.Reimbursement, error) {
	var reimbursements []domain.Reimbursement
	err := r.db.Preload("Approver").
		Where("employee_id = ?", employeeID).
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&reimbursements).Error
	return reimbursements, err
}

func (r *reimbursementRepository) GetAll(status string, limit, offset int) ([]domain.Reimbursement, error) {
	var reimbursements []domain.Reimbursement
	query := r.db.Preload("Employee").Preload("Approver")
	if status != "" {
		query = query.Where("status = ?", status)
	}
	err := query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&reimbursements).Error
	return reimbursements, err
}

func (r *reimbursementRepository) Update(reimbursement *domain.Reimbursement) error {
	return r.db.Save(reimbursement).Error
}

func (r *reimbursementRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&domain.Reimbursement{}, "id = ?", id).Error
}

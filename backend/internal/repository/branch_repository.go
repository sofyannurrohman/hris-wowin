package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type BranchRepository interface {
	Create(branch *domain.Branch) error
	FindAll() ([]domain.Branch, error)
	FindByID(id uuid.UUID) (*domain.Branch, error)
	Update(branch *domain.Branch) error
	Delete(id uuid.UUID) error
}

type branchRepository struct {
	db *gorm.DB
}

func NewBranchRepository(db *gorm.DB) BranchRepository {
	return &branchRepository{db}
}

func (r *branchRepository) Create(branch *domain.Branch) error {
	return r.db.Create(branch).Error
}

func (r *branchRepository) FindAll() ([]domain.Branch, error) {
	var branches []domain.Branch
	if err := r.db.Preload("Company").Find(&branches).Error; err != nil {
		return nil, err
	}
	return branches, nil
}

func (r *branchRepository) FindByID(id uuid.UUID) (*domain.Branch, error) {
	var branch domain.Branch
	if err := r.db.Preload("Company").Where("id = ?", id).First(&branch).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &branch, nil
}

func (r *branchRepository) Update(branch *domain.Branch) error {
	return r.db.Omit("Company").Save(branch).Error
}

func (r *branchRepository) Delete(id uuid.UUID) error {
	return r.db.Where("id = ?", id).Delete(&domain.Branch{}).Error
}

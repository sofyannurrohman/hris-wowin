package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type CompanyRepository interface {
	Create(company *domain.Company) error
	FindAll() ([]domain.Company, error)
	FindByID(id uuid.UUID) (*domain.Company, error)
	Update(company *domain.Company) error
	Delete(id uuid.UUID) error
}

type companyRepository struct {
	db *gorm.DB
}

func NewCompanyRepository(db *gorm.DB) CompanyRepository {
	return &companyRepository{db}
}

func (r *companyRepository) Create(company *domain.Company) error {
	return r.db.Create(company).Error
}

func (r *companyRepository) FindAll() ([]domain.Company, error) {
	var companies []domain.Company
	if err := r.db.Find(&companies).Error; err != nil {
		return nil, err
	}
	return companies, nil
}

func (r *companyRepository) FindByID(id uuid.UUID) (*domain.Company, error) {
	var company domain.Company
	if err := r.db.Where("id = ?", id).First(&company).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &company, nil
}

func (r *companyRepository) Update(company *domain.Company) error {
	return r.db.Save(company).Error
}

func (r *companyRepository) Delete(id uuid.UUID) error {
	return r.db.Where("id = ?", id).Delete(&domain.Company{}).Error
}

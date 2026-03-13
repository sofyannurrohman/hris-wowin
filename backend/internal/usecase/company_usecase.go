package usecase

import (
	"errors"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type CompanyUseCase interface {
	CreateCompany(req *CreateCompanyRequest) error
	GetCompanies() ([]domain.Company, error)
	GetCompanyByID(id uuid.UUID) (*domain.Company, error)
	UpdateCompany(id uuid.UUID, req *UpdateCompanyRequest) error
	DeleteCompany(id uuid.UUID) error
}

type companyUseCase struct {
	repo repository.CompanyRepository
}

type CreateCompanyRequest struct {
	Name      string `json:"name" binding:"required"`
	TaxNumber string `json:"taxNumber"`
	Address   string `json:"address"`
	LogoURL   string `json:"logoUrl"`
}

type UpdateCompanyRequest struct {
	Name      string `json:"name" binding:"required"`
	TaxNumber string `json:"taxNumber"`
	Address   string `json:"address"`
	LogoURL   string `json:"logoUrl"`
}

func NewCompanyUseCase(repo repository.CompanyRepository) CompanyUseCase {
	return &companyUseCase{repo: repo}
}

func (u *companyUseCase) CreateCompany(req *CreateCompanyRequest) error {
	company := &domain.Company{
		Name:      req.Name,
		TaxNumber: req.TaxNumber,
		Address:   req.Address,
		LogoURL:   req.LogoURL,
	}

	return u.repo.Create(company)
}

func (u *companyUseCase) GetCompanies() ([]domain.Company, error) {
	return u.repo.FindAll()
}

func (u *companyUseCase) GetCompanyByID(id uuid.UUID) (*domain.Company, error) {
	return u.repo.FindByID(id)
}

func (u *companyUseCase) UpdateCompany(id uuid.UUID, req *UpdateCompanyRequest) error {
	company, err := u.repo.FindByID(id)
	if err != nil {
		return err
	}
	if company == nil {
		return errors.New("company not found")
	}

	company.Name = req.Name
	company.TaxNumber = req.TaxNumber
	company.Address = req.Address
	company.LogoURL = req.LogoURL

	return u.repo.Update(company)
}

func (u *companyUseCase) DeleteCompany(id uuid.UUID) error {
	return u.repo.Delete(id)
}

package usecase

import (
	"errors"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type BranchUseCase interface {
	CreateBranch(req *CreateBranchRequest) error
	GetBranches() ([]domain.Branch, error)
	GetBranchesByCompany(companyID uuid.UUID) ([]domain.Branch, error)
	GetBranchByID(id uuid.UUID) (*domain.Branch, error)
	UpdateBranch(id uuid.UUID, req *UpdateBranchRequest) error
	DeleteBranch(id uuid.UUID) error
}

type branchUseCase struct {
	repo repository.BranchRepository
}

type CreateBranchRequest struct {
	CompanyID   *uuid.UUID `json:"companyId" binding:"required"`
	Name        string     `json:"name" binding:"required"`
	Address     string     `json:"address"`
	Timezone    string     `json:"timezone"`
	Latitude    float64    `json:"latitude"`
	Longitude   float64    `json:"longitude"`
	RadiusMeter int        `json:"radiusMeter"`
}

type UpdateBranchRequest struct {
	CompanyID   string `json:"companyId" binding:"omitempty"`
	Name        string `json:"name" binding:"required"`
	Address     string `json:"address"`
	Timezone    string `json:"timezone"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	RadiusMeter int `json:"radiusMeter"`
}

func NewBranchUseCase(repo repository.BranchRepository) BranchUseCase {
	return &branchUseCase{repo: repo}
}

func (u *branchUseCase) CreateBranch(req *CreateBranchRequest) error {
	timezone := req.Timezone
	if timezone == "" {
		timezone = "Asia/Jakarta"
	}
	radiusMeter := req.RadiusMeter
	if radiusMeter == 0 {
		radiusMeter = 100
	}

	branch := &domain.Branch{
		CompanyID:   req.CompanyID,
		Name:        req.Name,
		Address:     req.Address,
		Timezone:    timezone,
		Latitude:    req.Latitude,
		Longitude:   req.Longitude,
		RadiusMeter: radiusMeter,
	}

	return u.repo.Create(branch)
}

func (u *branchUseCase) GetBranches() ([]domain.Branch, error) {
	return u.repo.FindAll()
}

func (u *branchUseCase) GetBranchesByCompany(companyID uuid.UUID) ([]domain.Branch, error) {
	return u.repo.FindByCompanyID(companyID)
}

func (u *branchUseCase) GetBranchByID(id uuid.UUID) (*domain.Branch, error) {
	return u.repo.FindByID(id)
}

func (u *branchUseCase) UpdateBranch(id uuid.UUID, req *UpdateBranchRequest) error {
	branch, err := u.repo.FindByID(id)
	if err != nil {
		return err
	}
	if branch == nil {
		return errors.New("branch not found")
	}

// Update CompanyID if provided
if req.CompanyID != "" {
    parsedID, err := uuid.Parse(req.CompanyID)
    if err != nil {
        return err
    }
    branch.CompanyID = &parsedID
} else {
    branch.CompanyID = nil
}
branch.Name = req.Name
branch.Address = req.Address
branch.Timezone = req.Timezone
branch.Latitude = req.Latitude
branch.Longitude = req.Longitude
branch.RadiusMeter = req.RadiusMeter

	return u.repo.Update(branch)
}

func (u *branchUseCase) DeleteBranch(id uuid.UUID) error {
	return u.repo.Delete(id)
}

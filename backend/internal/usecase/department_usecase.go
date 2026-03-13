package usecase

import (
	"errors"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type DepartmentUseCase interface {
	CreateDepartment(req *CreateDepartmentRequest) error
	GetDepartments() ([]domain.Department, error)
	GetDepartmentByID(id uuid.UUID) (*domain.Department, error)
	UpdateDepartment(id uuid.UUID, req *UpdateDepartmentRequest) error
	DeleteDepartment(id uuid.UUID) error
}

type departmentUseCase struct {
	repo repository.DepartmentRepository
}

type CreateDepartmentRequest struct {
	CompanyID *uuid.UUID `json:"companyId"`
	Name      string     `json:"name" binding:"required"`
	ParentID  *uuid.UUID `json:"parentId"`
}

type UpdateDepartmentRequest struct {
	Name     string     `json:"name" binding:"required"`
	ParentID *uuid.UUID `json:"parentId"`
}

func NewDepartmentUseCase(repo repository.DepartmentRepository) DepartmentUseCase {
	return &departmentUseCase{repo: repo}
}

func (u *departmentUseCase) CreateDepartment(req *CreateDepartmentRequest) error {
	department := &domain.Department{
		CompanyID: req.CompanyID,
		Name:      req.Name,
		ParentID:  req.ParentID,
	}

	return u.repo.Create(department)
}

func (u *departmentUseCase) GetDepartments() ([]domain.Department, error) {
	return u.repo.FindAll()
}

func (u *departmentUseCase) GetDepartmentByID(id uuid.UUID) (*domain.Department, error) {
	return u.repo.FindByID(id)
}

func (u *departmentUseCase) UpdateDepartment(id uuid.UUID, req *UpdateDepartmentRequest) error {
	department, err := u.repo.FindByID(id)
	if err != nil {
		return err
	}
	if department == nil {
		return errors.New("department not found")
	}

	department.Name = req.Name
	// Optional assignment for parent department updates
	if req.ParentID != nil && *req.ParentID != uuid.Nil {
		department.ParentID = req.ParentID
	} else {
		department.ParentID = nil
	}

	return u.repo.Update(department)
}

func (u *departmentUseCase) DeleteDepartment(id uuid.UUID) error {
	return u.repo.Delete(id)
}

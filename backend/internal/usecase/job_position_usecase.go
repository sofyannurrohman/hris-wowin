package usecase

import (
	"errors"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type JobPositionUseCase interface {
	CreateJobPosition(req *CreateJobPositionRequest) error
	GetJobPositions() ([]domain.JobPosition, error)
	GetJobPositionByID(id uuid.UUID) (*domain.JobPosition, error)
	UpdateJobPosition(id uuid.UUID, req *UpdateJobPositionRequest) error
	DeleteJobPosition(id uuid.UUID) error
}

type jobPositionUseCase struct {
	repo repository.JobPositionRepository
}

type CreateJobPositionRequest struct {
	Title     string     `json:"title" binding:"required"`
	Level     int        `json:"level"`
	CompanyID *uuid.UUID `json:"companyId"`
}

type UpdateJobPositionRequest struct {
	Title string `json:"title" binding:"required"`
	Level int    `json:"level"`
}

func NewJobPositionUseCase(repo repository.JobPositionRepository) JobPositionUseCase {
	return &jobPositionUseCase{repo: repo}
}

func (u *jobPositionUseCase) CreateJobPosition(req *CreateJobPositionRequest) error {
	position := &domain.JobPosition{
		Title:     req.Title,
		Level:     req.Level,
		CompanyID: req.CompanyID,
	}

	return u.repo.Create(position)
}

func (u *jobPositionUseCase) GetJobPositions() ([]domain.JobPosition, error) {
	return u.repo.FindAll()
}

func (u *jobPositionUseCase) GetJobPositionByID(id uuid.UUID) (*domain.JobPosition, error) {
	return u.repo.FindByID(id)
}

func (u *jobPositionUseCase) UpdateJobPosition(id uuid.UUID, req *UpdateJobPositionRequest) error {
	position, err := u.repo.FindByID(id)
	if err != nil {
		return err
	}
	if position == nil {
		return errors.New("job position not found")
	}

	position.Title = req.Title
	position.Level = req.Level

	return u.repo.Update(position)
}

func (u *jobPositionUseCase) DeleteJobPosition(id uuid.UUID) error {
	return u.repo.Delete(id)
}

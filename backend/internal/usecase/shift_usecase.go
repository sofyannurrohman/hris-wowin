package usecase

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type ShiftUseCase interface {
	CreateShift(req *CreateShiftRequest) error
	GetShifts() ([]domain.Shift, error)
	GetShiftByID(id uuid.UUID) (*domain.Shift, error)
	UpdateShift(id uuid.UUID, req *UpdateShiftRequest) error
	DeleteShift(id uuid.UUID) error
}

type shiftUseCase struct {
	repo repository.ShiftRepository
}

type CreateShiftRequest struct {
	CompanyID  *uuid.UUID `json:"companyId"`
	Name       string     `json:"name" binding:"required"`
	StartTime  time.Time  `json:"startTime" binding:"required"`
	EndTime    time.Time  `json:"endTime" binding:"required"`
	BreakStart *time.Time `json:"breakStart"`
	BreakEnd   *time.Time `json:"breakEnd"`
	IsFlexible bool       `json:"isFlexible"`
	BranchID   *uuid.UUID `json:"branchId"`
}

type UpdateShiftRequest struct {
	Name       string     `json:"name" binding:"required"`
	StartTime  time.Time  `json:"startTime" binding:"required"`
	EndTime    time.Time  `json:"endTime" binding:"required"`
	BreakStart *time.Time `json:"breakStart"`
	BreakEnd   *time.Time `json:"breakEnd"`
	IsFlexible bool       `json:"isFlexible"`
	BranchID   *uuid.UUID `json:"branchId"`
}

func NewShiftUseCase(repo repository.ShiftRepository) ShiftUseCase {
	return &shiftUseCase{repo: repo}
}

func (u *shiftUseCase) CreateShift(req *CreateShiftRequest) error {
	shift := &domain.Shift{
		CompanyID:  req.CompanyID,
		Name:       req.Name,
		StartTime:  req.StartTime,
		EndTime:    req.EndTime,
		BreakStart: req.BreakStart,
		BreakEnd:   req.BreakEnd,
		BranchID:   req.BranchID,
		IsFlexible: req.IsFlexible,
	}

	return u.repo.Create(shift)
}

func (u *shiftUseCase) GetShifts() ([]domain.Shift, error) {
	return u.repo.FindAll()
}

func (u *shiftUseCase) GetShiftByID(id uuid.UUID) (*domain.Shift, error) {
	return u.repo.FindByID(id)
}

func (u *shiftUseCase) UpdateShift(id uuid.UUID, req *UpdateShiftRequest) error {
	shift, err := u.repo.FindByID(id)
	if err != nil {
		return err
	}
	if shift == nil {
		return errors.New("shift not found")
	}

	shift.Name = req.Name
	shift.StartTime = req.StartTime
	shift.EndTime = req.EndTime
	shift.BreakStart = req.BreakStart
	shift.BreakEnd = req.BreakEnd
	shift.BranchID = req.BranchID
	shift.IsFlexible = req.IsFlexible

	return u.repo.Update(shift)
}

func (u *shiftUseCase) DeleteShift(id uuid.UUID) error {
	return u.repo.Delete(id)
}

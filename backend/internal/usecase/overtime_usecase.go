package usecase

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type OvertimeUseCase interface {
	RequestOvertime(userID uuid.UUID, req OvertimeRequest) (*domain.Overtime, error)
	GetUserOvertimes(userID uuid.UUID) ([]domain.Overtime, error)
	GetAllOvertimes() ([]domain.Overtime, error)
	UpdateOvertimeStatus(id uuid.UUID, approverID uuid.UUID, status string, rejectReason *string) error
	UpdateOvertime(userID uuid.UUID, id uuid.UUID, req OvertimeRequest) error
	DeleteOvertime(userID uuid.UUID, id uuid.UUID) error
}

type overtimeUseCase struct {
	repo         repository.OvertimeRepository
	employeeRepo repository.EmployeeRepository
}

func NewOvertimeUseCase(repo repository.OvertimeRepository, employeeRepo repository.EmployeeRepository) OvertimeUseCase {
	return &overtimeUseCase{repo, employeeRepo}
}

type OvertimeRequest struct {
	Date            string `json:"date" binding:"required"`       // YYYY-MM-DD format
	StartTime       string `json:"start_time" binding:"required"` // RFC3339 or similar parseable time
	EndTime         string `json:"end_time" binding:"required"`
	DurationMinutes int    `json:"duration_minutes" binding:"required"`
	Reason          string `json:"reason" binding:"required"`
}

func parseDateTime(s string) (time.Time, error) {
	formats := []string{
		time.RFC3339,
		"2006-01-02T15:04:05.999Z07:00",
		"2006-01-02T15:04:05.999",
		"2006-01-02T15:04:05",
	}

	for _, f := range formats {
		if t, err := time.Parse(f, s); err == nil {
			return t, nil
		}
	}
	return time.Time{}, errors.New("invalid date time format: " + s)
}


func (u *overtimeUseCase) RequestOvertime(userID uuid.UUID, req OvertimeRequest) (*domain.Overtime, error) {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil || employee == nil {
		return nil, errors.New("employee record not found")
	}

	date, err := time.Parse("2006-01-02", req.Date)
	if err != nil {
		return nil, errors.New("invalid date format, use YYYY-MM-DD")
	}

	start, err := parseDateTime(req.StartTime)
	if err != nil {
		return nil, errors.New("invalid start_time format: " + err.Error())
	}

	end, err := parseDateTime(req.EndTime)
	if err != nil {
		return nil, errors.New("invalid end_time format: " + err.Error())
	}


	overtime := &domain.Overtime{
		EmployeeID:      employee.ID,
		Date:            date,
		StartTime:       start,
		EndTime:         end,
		DurationMinutes: req.DurationMinutes,
		Reason:          req.Reason,
		Status:          domain.OvertimePending,
	}

	if err := u.repo.Create(overtime); err != nil {
		return nil, err
	}
	return overtime, nil
}

func (u *overtimeUseCase) GetUserOvertimes(userID uuid.UUID) ([]domain.Overtime, error) {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil || employee == nil {
		return nil, errors.New("employee record not found")
	}
	return u.repo.FindByEmployeeID(employee.ID)
}

func (u *overtimeUseCase) GetAllOvertimes() ([]domain.Overtime, error) {
	return u.repo.FindAll()
}

func (u *overtimeUseCase) UpdateOvertimeStatus(id uuid.UUID, approverUserID uuid.UUID, status string, rejectReason *string) error {
	approverEmployee, err := u.employeeRepo.FindByUserID(approverUserID)
	if err != nil || approverEmployee == nil {
		return errors.New("approver employee record not found")
	}

	s := domain.OvertimeStatus(status)
	if s != domain.OvertimePending && s != domain.OvertimeApproved && s != domain.OvertimeRejected {
		return errors.New("invalid status")
	}

	return u.repo.UpdateStatus(id, s, &approverEmployee.ID, rejectReason)
}
func (u *overtimeUseCase) UpdateOvertime(userID uuid.UUID, id uuid.UUID, req OvertimeRequest) error {
	overtime, err := u.repo.FindByID(id)
	if err != nil {
		return err
	}

	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil || employee == nil {
		return errors.New("employee record not found")
	}

	if overtime.EmployeeID != employee.ID {
		return errors.New("you can only update your own overtime requests")
	}

	if overtime.Status != domain.OvertimePending {
		return errors.New("you can only update pending overtime requests")
	}

	date, _ := time.Parse("2006-01-02", req.Date)
	start, _ := parseDateTime(req.StartTime)
	end, _ := parseDateTime(req.EndTime)

	overtime.Date = date
	overtime.StartTime = start
	overtime.EndTime = end
	overtime.DurationMinutes = req.DurationMinutes
	overtime.Reason = req.Reason

	return u.repo.Update(overtime)
}

func (u *overtimeUseCase) DeleteOvertime(userID uuid.UUID, id uuid.UUID) error {
	overtime, err := u.repo.FindByID(id)
	if err != nil {
		return err
	}

	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil || employee == nil {
		return errors.New("employee record not found")
	}

	if overtime.EmployeeID != employee.ID {
		return errors.New("you can only delete your own overtime requests")
	}

	if overtime.Status != domain.OvertimePending {
		return errors.New("you can only delete pending overtime requests")
	}

	return u.repo.Delete(id)
}

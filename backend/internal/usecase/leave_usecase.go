package usecase

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type LeaveUseCase interface {
	SubmitLeave(userID uuid.UUID, req SubmitLeaveRequest) error
	UpdateMyLeave(leaveID, userID uuid.UUID, req SubmitLeaveRequest) error
	DeleteMyLeave(leaveID, userID uuid.UUID) error
	AdminCreateLeave(req AdminLeaveRequest) error
	AdminUpdateLeave(leaveID uuid.UUID, req AdminLeaveRequest) error
	AdminDeleteLeave(leaveID uuid.UUID) error
	GetMyLeaves(userID uuid.UUID, page, limit int) ([]domain.LeaveRequest, error)
	GetMyBalances(userID uuid.UUID) ([]LeaveBalanceResponse, error)
	GetAllLeaves(status string, page, limit int) ([]domain.LeaveRequest, error)
	GetAllLeaveBalances() ([]*domain.LeaveBalance, error)
	ApproveReturnLeave(leaveID, approverID uuid.UUID, req ApproveLeaveRequest) error
}

type leaveUseCase struct {
	repo         repository.LeaveRepository
	employeeRepo repository.EmployeeRepository
}

func NewLeaveUseCase(repo repository.LeaveRepository, employeeRepo repository.EmployeeRepository) LeaveUseCase {
	return &leaveUseCase{repo, employeeRepo}
}

type SubmitLeaveRequest struct {
	LeaveTypeID   string `json:"leave_type_id" form:"leave_type_id" binding:"required"`
	StartDate     string `json:"start_date" form:"start_date" binding:"required"`
	EndDate       string `json:"end_date" form:"end_date" binding:"required"`
	Reason        string `json:"reason" form:"reason" binding:"required"`
	AttachmentURL string `json:"attachment_url" form:"attachment_url"`
}

type LeaveBalanceResponse struct {
	LeaveTypeID   string `json:"leave_type_id"`
	LeaveTypeName string `json:"leave_type_name"`
	IsPaid        bool   `json:"is_paid"`
	Total         int    `json:"total"`
	Used          int    `json:"used"`
	Remaining     int    `json:"remaining"`
}

type ApproveLeaveRequest struct {
	Status       string `json:"status" binding:"required,oneof=APPROVED REJECTED"`
	RejectReason string `json:"reject_reason"`
}

type AdminLeaveRequest struct {
	EmployeeID    string `json:"employee_id" binding:"required"`
	LeaveTypeID   string `json:"leave_type_id" binding:"required"`
	StartDate     string `json:"start_date" binding:"required"`
	EndDate       string `json:"end_date" binding:"required"`
	Reason        string `json:"reason"`
	AttachmentURL string `json:"attachment_url"`
	Status        string `json:"status"` // PENDING, APPROVED, REJECTED
}

func (u *leaveUseCase) SubmitLeave(userID uuid.UUID, req SubmitLeaveRequest) error {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return err
	}
	if employee == nil {
		return errors.New("employee record not found")
	}

	layout := "2006-01-02"
	start, err := time.Parse(layout, req.StartDate)
	if err != nil {
		return errors.New("invalid start date format, expected YYYY-MM-DD")
	}
	end, err := time.Parse(layout, req.EndDate)
	if err != nil {
		return errors.New("invalid end date format, expected YYYY-MM-DD")
	}

	if end.Before(start) {
		return errors.New("end date cannot be before start date")
	}

	// Calculate total days
	duration := end.Sub(start)
	totalDays := int(duration.Hours()/24) + 1

	leaveTypeID, err := uuid.Parse(req.LeaveTypeID)
	if err != nil {
		return errors.New("invalid leave_type_id format")
	}

	leaveType, err := u.repo.GetLeaveTypeByID(leaveTypeID)
	if err != nil {
		return errors.New("leave type not found")
	}

	// VALIDATION: Sakit must have attachment
	if strings.Contains(strings.ToLower(leaveType.Name), "sakit") && req.AttachmentURL == "" {
		return errors.New("Surat izin dokter wajib dilampirkan untuk izin sakit")
	}

	var balanceToUpdate *domain.LeaveBalance
	currentYear := time.Now().Year()

	if leaveType.IsPaid {
		balance, err := u.repo.GetLeaveBalance(employee.ID, leaveType.ID, currentYear)
		if err != nil {
			return errors.New("leave balance not found for this year")
		}

		remaining := balance.BalanceTotal - balance.BalanceUsed
		if remaining < totalDays {
			return errors.New("insufficient leave balance")
		}

		balance.BalanceUsed += totalDays
		balanceToUpdate = balance
	}

	leave := &domain.LeaveRequest{
		EmployeeID:    employee.ID,
		LeaveTypeID:   leaveType.ID,
		StartDate:     start,
		EndDate:       end,
		Reason:        req.Reason,
		AttachmentURL: req.AttachmentURL,
		Status:        "PENDING",
	}

	return u.repo.CreateLeaveRequestWithBalance(leave, balanceToUpdate)
}

func (u *leaveUseCase) UpdateMyLeave(leaveID, userID uuid.UUID, req SubmitLeaveRequest) error {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return err
	}
	if employee == nil {
		return errors.New("employee record not found")
	}

	leave, err := u.repo.FindByID(leaveID)
	if err != nil || leave == nil {
		return errors.New("leave request not found")
	}

	if leave.EmployeeID != employee.ID {
		return errors.New("you can only update your own leave requests")
	}

	if leave.Status != "PENDING" {
		return errors.New("only pending leave requests can be updated")
	}

	layout := "2006-01-02"
	newStart, err := time.Parse(layout, req.StartDate)
	if err != nil {
		return errors.New("invalid start date format")
	}
	newEnd, err := time.Parse(layout, req.EndDate)
	if err != nil {
		return errors.New("invalid end date format")
	}
	if newEnd.Before(newStart) {
		return errors.New("end date cannot be before start date")
	}

	newDuration := newEnd.Sub(newStart)
	newTotalDays := int(newDuration.Hours()/24) + 1

	newLeaveTypeID, _ := uuid.Parse(req.LeaveTypeID)
	newLeaveType, _ := u.repo.GetLeaveTypeByID(newLeaveTypeID)
	if newLeaveType == nil {
		return errors.New("leave type not found")
	}

	var balanceToUpdate *domain.LeaveBalance
	currentYear := time.Now().Year()

	if leave.LeaveTypeID != newLeaveTypeID || !leave.StartDate.Equal(newStart) || !leave.EndDate.Equal(newEnd) {
		oldLeaveType, _ := u.repo.GetLeaveTypeByID(leave.LeaveTypeID)
		if oldLeaveType != nil && oldLeaveType.IsPaid {
			oldDuration := leave.EndDate.Sub(leave.StartDate)
			oldTotalDays := int(oldDuration.Hours()/24) + 1
			balance, err := u.repo.GetLeaveBalance(employee.ID, leave.LeaveTypeID, leave.StartDate.Year())
			if err == nil {
				balance.BalanceUsed -= oldTotalDays
				balanceToUpdate = balance
			}
		}

		if newLeaveType.IsPaid {
			balance := balanceToUpdate
			if balance == nil || balance.LeaveTypeID != newLeaveTypeID {
				balance, err = u.repo.GetLeaveBalance(employee.ID, newLeaveTypeID, currentYear)
				if err != nil {
					return errors.New("insufficient leave balance record for this year")
				}
			}

			remaining := (balance.BalanceTotal - balance.BalanceUsed)
			if remaining < newTotalDays {
				return errors.New("insufficient leave balance")
			}
			balance.BalanceUsed += newTotalDays
			balanceToUpdate = balance
		}
	}

	leave.LeaveTypeID = newLeaveTypeID
	leave.StartDate = newStart
	leave.EndDate = newEnd
	leave.Reason = req.Reason
	if req.AttachmentURL != "" {
		leave.AttachmentURL = req.AttachmentURL
	}

	return u.repo.UpdateLeaveRequestStatus(leave, balanceToUpdate)
}

func (u *leaveUseCase) DeleteMyLeave(leaveID, userID uuid.UUID) error {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return err
	}
	if employee == nil {
		return errors.New("employee record not found")
	}

	leave, err := u.repo.FindByID(leaveID)
	if err != nil || leave == nil {
		return errors.New("leave request not found")
	}

	if leave.EmployeeID != employee.ID {
		return errors.New("you can only delete your own leave requests")
	}

	if leave.Status != "PENDING" {
		return errors.New("only pending leave requests can be deleted")
	}

	var balanceToRefund *domain.LeaveBalance
	leaveType, _ := u.repo.GetLeaveTypeByID(leave.LeaveTypeID)
	if leaveType != nil && leaveType.IsPaid {
		duration := leave.EndDate.Sub(leave.StartDate)
		totalDays := int(duration.Hours()/24) + 1

		currentYear := leave.StartDate.Year()
		balance, err := u.repo.GetLeaveBalance(leave.EmployeeID, leave.LeaveTypeID, currentYear)
		if err == nil {
			balance.BalanceUsed -= totalDays
			balanceToRefund = balance
		}
	}

	leave.Status = "CANCELLED"
	return u.repo.UpdateLeaveRequestStatus(leave, balanceToRefund)
}

func (u *leaveUseCase) AdminCreateLeave(req AdminLeaveRequest) error {
	layout := "2006-01-02"
	start, err := time.Parse(layout, req.StartDate)
	if err != nil {
		return errors.New("invalid start_date format")
	}
	end, err := time.Parse(layout, req.EndDate)
	if err != nil {
		return errors.New("invalid end_date format")
	}
	if end.Before(start) {
		return errors.New("end date cannot be before start date")
	}

	employeeID, err := uuid.Parse(req.EmployeeID)
	if err != nil {
		return errors.New("invalid employee_id")
	}
	leaveTypeID, err := uuid.Parse(req.LeaveTypeID)
	if err != nil {
		return errors.New("invalid leave_type_id")
	}

	leave := &domain.LeaveRequest{
		EmployeeID:    employeeID,
		LeaveTypeID:   leaveTypeID,
		StartDate:     start,
		EndDate:       end,
		Reason:        req.Reason,
		AttachmentURL: req.AttachmentURL,
		Status:        "PENDING",
	}
	return u.repo.Create(leave)
}

func (u *leaveUseCase) AdminUpdateLeave(leaveID uuid.UUID, req AdminLeaveRequest) error {
	leave, err := u.repo.FindByID(leaveID)
	if err != nil || leave == nil {
		return errors.New("leave request not found")
	}

	layout := "2006-01-02"
	if req.StartDate != "" {
		if t, e := time.Parse(layout, req.StartDate); e == nil {
			leave.StartDate = t
		}
	}
	if req.EndDate != "" {
		if t, e := time.Parse(layout, req.EndDate); e == nil {
			leave.EndDate = t
		}
	}
	if req.LeaveTypeID != "" {
		if id, e := uuid.Parse(req.LeaveTypeID); e == nil {
			leave.LeaveTypeID = id
		}
	}
	leave.Reason = req.Reason
	leave.AttachmentURL = req.AttachmentURL
	if req.Status != "" {
		leave.Status = req.Status
	}
	return u.repo.Update(leave)
}

func (u *leaveUseCase) AdminDeleteLeave(leaveID uuid.UUID) error {
	return u.repo.Delete(leaveID)
}

func (u *leaveUseCase) GetMyLeaves(userID uuid.UUID, page, limit int) ([]domain.LeaveRequest, error) {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return nil, err
	}
	if employee == nil {
		return nil, errors.New("employee record not found")
	}

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	offset := (page - 1) * limit

	return u.repo.FindByUserID(employee.ID, limit, offset)
}

func (u *leaveUseCase) GetMyBalances(userID uuid.UUID) ([]LeaveBalanceResponse, error) {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return nil, err
	}
	if employee == nil {
		return nil, errors.New("employee record not found")
	}

	currentYear := time.Now().Year()
	balances, err := u.repo.GetAllBalancesByEmployee(employee.ID, currentYear)
	if err != nil {
		return nil, err
	}

	var res []LeaveBalanceResponse
	for _, b := range balances {
		name := ""
		if b.LeaveType != nil {
			name = b.LeaveType.Name
		}
		res = append(res, LeaveBalanceResponse{
			LeaveTypeID:   b.LeaveTypeID.String(),
			LeaveTypeName: name,
			IsPaid:        b.LeaveType.IsPaid,
			Total:         b.BalanceTotal,
			Used:          b.BalanceUsed,
			Remaining:     b.BalanceTotal - b.BalanceUsed,
		})
	}
	if res == nil {
		res = []LeaveBalanceResponse{}
	}
	return res, nil
}

func (u *leaveUseCase) GetAllLeaveBalances() ([]*domain.LeaveBalance, error) {
	return u.repo.GetAllBalances()
}

func (u *leaveUseCase) GetAllLeaves(status string, page, limit int) ([]domain.LeaveRequest, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	offset := (page - 1) * limit

	return u.repo.FindAll(status, limit, offset)
}

func (u *leaveUseCase) ApproveReturnLeave(leaveID, approverID uuid.UUID, req ApproveLeaveRequest) error {
	leave, err := u.repo.FindByID(leaveID)
	if err != nil {
		return err
	}
	if leave == nil {
		return errors.New("leave request not found")
	}

	if leave.Status != "PENDING" {
		return errors.New("leave request is not in pending state")
	}

	if req.Status == "REJECTED" && len(req.RejectReason) == 0 {
		return errors.New("reject reason is required when status is REJECTED")
	}

	var balanceToRefund *domain.LeaveBalance

	if req.Status == "REJECTED" {
		leaveType, _ := u.repo.GetLeaveTypeByID(leave.LeaveTypeID)
		if leaveType != nil && leaveType.IsPaid {
			duration := leave.EndDate.Sub(leave.StartDate)
			totalDays := int(duration.Hours()/24) + 1

			currentYear := leave.StartDate.Year()
			balance, err := u.repo.GetLeaveBalance(leave.EmployeeID, leave.LeaveTypeID, currentYear)
			if err == nil {
				balance.BalanceUsed -= totalDays
				balanceToRefund = balance
			}
		}
		leave.RejectReason = &req.RejectReason
	}

	approverEmp, err := u.employeeRepo.FindByUserID(approverID)
	if err != nil {
		return errors.New("failed to resolve approver identity")
	}
	if approverEmp == nil {
		return errors.New("approver employee record not found")
	}

	leave.Status = req.Status
	leave.ApprovedBy = &approverEmp.ID

	return u.repo.UpdateLeaveRequestStatus(leave, balanceToRefund)
}

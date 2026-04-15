package usecase

import (
	"errors"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type ReimbursementUseCase interface {
	Submit(userID uuid.UUID, req SubmitReimbursementRequest) error
	GetHistory(userID uuid.UUID, page, limit int) ([]domain.Reimbursement, error)
	GetAll(status string, page, limit int) ([]domain.Reimbursement, error)
	Approve(approverID, id uuid.UUID, req ApproveReimbursementRequest) error
}

type reimbursementUseCase struct {
	repo         repository.ReimbursementRepository
	employeeRepo repository.EmployeeRepository
}

func NewReimbursementUseCase(repo repository.ReimbursementRepository, employeeRepo repository.EmployeeRepository) ReimbursementUseCase {
	return &reimbursementUseCase{repo, employeeRepo}
}

type SubmitReimbursementRequest struct {
	Title         string  `json:"title" form:"title" binding:"required"`
	Description   string  `json:"description" form:"description"`
	Amount        float64 `json:"amount" form:"amount" binding:"required"`
	AttachmentURL string  `json:"attachment_url" form:"attachment_url"`
}

type ApproveReimbursementRequest struct {
	Status         string `json:"status" binding:"required,oneof=APPROVED REJECTED"`
	RejectedReason string `json:"rejected_reason"`
}

func (u *reimbursementUseCase) Submit(userID uuid.UUID, req SubmitReimbursementRequest) error {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return err
	}
	if employee == nil {
		return errors.New("employee record not found")
	}

	if req.AttachmentURL == "" {
		return errors.New("Bukti pembayaran (nota/struk) wajib dilampirkan")
	}

	reimbursement := &domain.Reimbursement{
		EmployeeID:    employee.ID,
		Title:         req.Title,
		Description:   req.Description,
		Amount:        req.Amount,
		AttachmentURL: req.AttachmentURL,
		Status:        domain.ReimbursementPending,
	}

	return u.repo.Create(reimbursement)
}

func (u *reimbursementUseCase) GetHistory(userID uuid.UUID, page, limit int) ([]domain.Reimbursement, error) {
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
	if limit < 1 {
		limit = 10
	}
	offset := (page - 1) * limit

	return u.repo.GetByEmployeeID(employee.ID, limit, offset)
}

func (u *reimbursementUseCase) GetAll(status string, page, limit int) ([]domain.Reimbursement, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	offset := (page - 1) * limit

	return u.repo.GetAll(status, limit, offset)
}

func (u *reimbursementUseCase) Approve(approverID, id uuid.UUID, req ApproveReimbursementRequest) error {
	reimbursement, err := u.repo.GetByID(id)
	if err != nil {
		return err
	}
	if reimbursement == nil {
		return errors.New("reimbursement request not found")
	}

	if reimbursement.Status != domain.ReimbursementPending {
		return errors.New("reimbursement is already processed")
	}

	// Resolve approver employee ID from User ID
	approver, err := u.employeeRepo.FindByUserID(approverID)
	if err != nil {
		return err
	}
	if approver == nil {
		return errors.New("approver employee record not found")
	}

	reimbursement.Status = domain.ReimbursementStatus(req.Status)
	reimbursement.ApprovedBy = &approver.ID
	if req.Status == string(domain.ReimbursementRejected) {
		reimbursement.RejectedReason = &req.RejectedReason
	}

	return u.repo.Update(reimbursement)
}

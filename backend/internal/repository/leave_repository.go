package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type LeaveRepository interface {
	Create(leave *domain.LeaveRequest) error
	Update(leave *domain.LeaveRequest) error
	FindByID(id uuid.UUID) (*domain.LeaveRequest, error)
	FindByUserID(userID uuid.UUID, limit, offset int) ([]domain.LeaveRequest, error)
	FindAll(status string, limit, offset int) ([]domain.LeaveRequest, error)
	GetLeaveTypeByID(id uuid.UUID) (*domain.LeaveType, error)
	GetLeaveBalance(employeeID uuid.UUID, leaveTypeID uuid.UUID, year int) (*domain.LeaveBalance, error)
	GetAllBalancesByEmployee(employeeID uuid.UUID, year int) ([]*domain.LeaveBalance, error)
	GetAllBalances() ([]*domain.LeaveBalance, error)
	CreateLeaveRequestWithBalance(req *domain.LeaveRequest, balance *domain.LeaveBalance) error
	UpdateLeaveRequestStatus(req *domain.LeaveRequest, balanceToRefund *domain.LeaveBalance) error
}

type leaveRepository struct {
	db *gorm.DB
}

func NewLeaveRepository(db *gorm.DB) LeaveRepository {
	return &leaveRepository{db}
}

func (r *leaveRepository) Create(leave *domain.LeaveRequest) error {
	return r.db.Create(leave).Error
}

func (r *leaveRepository) Update(leave *domain.LeaveRequest) error {
	return r.db.Save(leave).Error
}

func (r *leaveRepository) FindByID(id uuid.UUID) (*domain.LeaveRequest, error) {
	var leave domain.LeaveRequest
	err := r.db.Where("id = ?", id).First(&leave).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &leave, nil
}

func (r *leaveRepository) FindByUserID(employeeID uuid.UUID, limit, offset int) ([]domain.LeaveRequest, error) {
	var leaves []domain.LeaveRequest
	err := r.db.Where("employee_id = ?", employeeID).
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Preload("LeaveType").
		Find(&leaves).Error
	return leaves, err
}

func (r *leaveRepository) FindAll(status string, limit, offset int) ([]domain.LeaveRequest, error) {
	var leaves []domain.LeaveRequest
	query := r.db

	if status != "" {
		query = query.Where("status = ?", status)
	}

	err := query.Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Preload("Employee").
		Preload("LeaveType").
		Find(&leaves).Error

	return leaves, err
}

func (r *leaveRepository) GetLeaveTypeByID(id uuid.UUID) (*domain.LeaveType, error) {
	var leaveType domain.LeaveType
	err := r.db.Where("id = ?", id).First(&leaveType).Error
	return &leaveType, err
}

func (r *leaveRepository) GetLeaveBalance(employeeID uuid.UUID, leaveTypeID uuid.UUID, year int) (*domain.LeaveBalance, error) {
	var balance domain.LeaveBalance
	err := r.db.Where("employee_id = ? AND leave_type_id = ? AND year = ?", employeeID, leaveTypeID, year).First(&balance).Error
	return &balance, err
}

func (r *leaveRepository) GetAllBalancesByEmployee(employeeID uuid.UUID, year int) ([]*domain.LeaveBalance, error) {
	var balances []*domain.LeaveBalance
	err := r.db.Preload("LeaveType").Where("employee_id = ? AND year = ?", employeeID, year).Find(&balances).Error
	return balances, err
}

func (r *leaveRepository) GetAllBalances() ([]*domain.LeaveBalance, error) {
	var balances []*domain.LeaveBalance
	err := r.db.Preload("LeaveType").Preload("Employee").Order("year desc").Find(&balances).Error
	return balances, err
}

func (r *leaveRepository) CreateLeaveRequestWithBalance(req *domain.LeaveRequest, balance *domain.LeaveBalance) error {
	tx := r.db.Begin()

	if err := tx.Create(req).Error; err != nil {
		tx.Rollback()
		return err
	}

	if balance != nil {
		if err := tx.Save(balance).Error; err != nil {
			tx.Rollback()
			return err
		}
	}

	return tx.Commit().Error
}

func (r *leaveRepository) UpdateLeaveRequestStatus(req *domain.LeaveRequest, balanceToRefund *domain.LeaveBalance) error {
	tx := r.db.Begin()

	if err := tx.Save(req).Error; err != nil {
		tx.Rollback()
		return err
	}

	if balanceToRefund != nil {
		if err := tx.Save(balanceToRefund).Error; err != nil {
			tx.Rollback()
			return err
		}
	}

	return tx.Commit().Error
}

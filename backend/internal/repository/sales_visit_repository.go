package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type SalesVisitRepository interface {
	Create(visit *domain.SalesVisit) error
	Update(visit *domain.SalesVisit) error
	FindByID(id uuid.UUID) (*domain.SalesVisit, error)
	FindTodayByEmployeeAndStore(employeeID, storeID uuid.UUID) (*domain.SalesVisit, error)
	FindLatestByEmployeeStoreAndDate(employeeID, storeID uuid.UUID, date time.Time) (*domain.SalesVisit, error)
	FindAllHistory(limit, offset int, employeeID *uuid.UUID, branchID *uuid.UUID, startDate, endDate *time.Time) ([]domain.SalesVisit, error)
	Delete(id uuid.UUID) error
}

type salesVisitRepository struct {
	db *gorm.DB
}

func NewSalesVisitRepository(db *gorm.DB) SalesVisitRepository {
	return &salesVisitRepository{db}
}

func (r *salesVisitRepository) Create(visit *domain.SalesVisit) error {
	return r.db.Create(visit).Error
}

func (r *salesVisitRepository) Update(visit *domain.SalesVisit) error {
	return r.db.Save(visit).Error
}

func (r *salesVisitRepository) FindByID(id uuid.UUID) (*domain.SalesVisit, error) {
	var visit domain.SalesVisit
	err := r.db.Preload("Employee.User").Preload("Store").Preload("Transactions").Preload("SalesOrders").Where("id = ?", id).First(&visit).Error
	if err != nil {
		return nil, err
	}
	return &visit, nil
}

func (r *salesVisitRepository) FindTodayByEmployeeAndStore(employeeID, storeID uuid.UUID) (*domain.SalesVisit, error) {
	var visit domain.SalesVisit
	now := time.Now()
	// Look back 24 hours from now to find the latest visit for this store/employee
	// This handles cases where a visit crosses the UTC day boundary
	limit := now.Add(-24 * time.Hour)
	err := r.db.Where("employee_id = ? AND store_id = ? AND check_in_time >= ? AND check_in_time <= ?", employeeID, storeID, limit, now).
		Order("check_in_time DESC").
		First(&visit).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &visit, nil
}

func (r *salesVisitRepository) FindLatestByEmployeeStoreAndDate(employeeID, storeID uuid.UUID, date time.Time) (*domain.SalesVisit, error) {
	var visit domain.SalesVisit
	// Look back 24 hours from the given reference date to find the most recent visit
	// This is much more robust than strict "same UTC day" matching
	limit := date.Add(-24 * time.Hour)
	
	err := r.db.Where("employee_id = ? AND store_id = ? AND check_in_time <= ? AND check_in_time >= ?", employeeID, storeID, date, limit).
		Order("check_in_time DESC").
		First(&visit).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &visit, nil
}

func (r *salesVisitRepository) FindAllHistory(limit, offset int, employeeID *uuid.UUID, branchID *uuid.UUID, startDate, endDate *time.Time) ([]domain.SalesVisit, error) {
	var visits []domain.SalesVisit
	query := r.db.Model(&domain.SalesVisit{}).Preload("Employee.User").Preload("Employee.Branch").Preload("Store").Preload("Transactions").Preload("SalesOrders")
	
	if employeeID != nil && *employeeID != uuid.Nil {
		query = query.Where("employee_id = ?", *employeeID)
	}
	
	if branchID != nil && *branchID != uuid.Nil {
		query = query.Where("employee_id IN (SELECT id FROM employees WHERE branch_id = ?)", *branchID)
	}
	
	if startDate != nil {
		query = query.Where("check_in_time >= ?", *startDate)
	}
	if endDate != nil {
		query = query.Where("check_in_time <= ?", *endDate)
	}
	
	err := query.Order("check_in_time DESC").Limit(limit).Offset(offset).Find(&visits).Error
	return visits, err
}

func (r *salesVisitRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&domain.SalesVisit{}, id).Error
}

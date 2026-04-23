package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type EmployeeRepository interface {
	Create(employee *domain.Employee) error
	FindAll(limit int, branchID *uuid.UUID) ([]domain.Employee, error)
	FindByID(id uuid.UUID) (*domain.Employee, error)
	FindByUserID(userID uuid.UUID) (*domain.Employee, error)
	Update(employee *domain.Employee) error
	Delete(id uuid.UUID) error
	FindBirthdaysToday() ([]domain.Employee, error)
}

type employeeRepository struct {
	db *gorm.DB
}

func NewEmployeeRepository(db *gorm.DB) EmployeeRepository {
	return &employeeRepository{db}
}

func (r *employeeRepository) Create(employee *domain.Employee) error {
	return r.db.Create(employee).Error
}

func (r *employeeRepository) FindAll(limit int, branchID *uuid.UUID) ([]domain.Employee, error) {
	var employees []domain.Employee
	query := r.db.Preload("User").Preload("Branch").Preload("Department").Preload("JobPosition")
	if limit > 0 {
		query = query.Limit(limit)
	}
	if branchID != nil {
		query = query.Where("branch_id = ?", branchID)
	}
	if err := query.Find(&employees).Error; err != nil {
		return nil, err
	}
	return employees, nil
}

func (r *employeeRepository) FindByID(id uuid.UUID) (*domain.Employee, error) {
	var employee domain.Employee
	if err := r.db.Preload("User").Preload("Branch").Preload("Department").Preload("JobPosition").Where("id = ?", id).First(&employee).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &employee, nil
}

func (r *employeeRepository) FindByUserID(userID uuid.UUID) (*domain.Employee, error) {
	var employee domain.Employee
	if err := r.db.Preload("Branch").Preload("User").Preload("Department").Preload("JobPosition").Where("user_id = ?", userID).First(&employee).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &employee, nil
}

func (r *employeeRepository) Update(employee *domain.Employee) error {
	return r.db.Save(employee).Error
}

func (r *employeeRepository) Delete(id uuid.UUID) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// 1. Handle Payslip Items (via Payslips)
		// We need to delete payslip items before payslips
		if err := tx.Exec("DELETE FROM payslip_items WHERE payslip_id IN (SELECT id FROM payslips WHERE employee_id = ?)", id).Error; err != nil {
			return err
		}

		// 2. Delete dependent records using GORM's Where logic for safety
		dependentModels := []interface{}{
			&domain.Payslip{},
			&domain.EmployeeSalarySetting{},
			&domain.LeaveBalance{},
			&domain.LeaveRequest{},
			&domain.AttendanceLog{},
			&domain.EmployeeShift{},
			&domain.Reimbursement{},
			&domain.Overtime{},
			&domain.SalesKPI{},
			&domain.EmployeeKPI{},
			&domain.ManagerialAppraisal{},
		}

		for _, model := range dependentModels {
			if err := tx.Where("employee_id = ?", id).Delete(model).Error; err != nil {
				return err
			}
		}

		// 3. Handle specific FKs that might point to this employee as an approver/manager
		// Set ApprovedBy to NULL where this employee was the approver
		if err := tx.Model(&domain.LeaveRequest{}).Where("approved_by = ?", id).Update("approved_by", nil).Error; err != nil {
			return err
		}
		if err := tx.Model(&domain.Reimbursement{}).Where("approved_by = ?", id).Update("approved_by", nil).Error; err != nil {
			return err
		}
		if err := tx.Model(&domain.Overtime{}).Where("approved_by = ?", id).Update("approved_by", nil).Error; err != nil {
			return err
		}

		// Handle ManagerialAppraisal where this employee was the manager
		// Since ManagerID is NOT NULL, we must delete these appraisals
		if err := tx.Where("manager_id = ?", id).Delete(&domain.ManagerialAppraisal{}).Error; err != nil {
			return err
		}

		// 4. Update subordinates (set manager_id to NULL)
		if err := tx.Model(&domain.Employee{}).Where("manager_id = ?", id).Update("manager_id", nil).Error; err != nil {
			return err
		}

		// 5. Finally delete the employee record
		if err := tx.Where("id = ?", id).Delete(&domain.Employee{}).Error; err != nil {
			return err
		}

		return nil
	})
}

func (r *employeeRepository) FindBirthdaysToday() ([]domain.Employee, error) {
	var employees []domain.Employee
	// Postgres syntax for extracting month and day
	if err := r.db.Where("EXTRACT(MONTH FROM birth_date) = EXTRACT(MONTH FROM CURRENT_DATE) AND EXTRACT(DAY FROM birth_date) = EXTRACT(DAY FROM CURRENT_DATE)").Find(&employees).Error; err != nil {
		return nil, err
	}
	return employees, nil
}

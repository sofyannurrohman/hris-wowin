package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type PayrollRepository interface {
	GetActiveEmployees() ([]uuid.UUID, error)
	GetEmployeeSnapshotInfo(employeeID uuid.UUID) (string, string)
	GetEmployeeSalarySettings(employeeID uuid.UUID) ([]domain.EmployeeSalarySetting, error)
	GetEmployeeAbsentDays(employeeID uuid.UUID, startDate, endDate time.Time) (int, error)
	GetMyPayslips(employeeID uuid.UUID) ([]domain.Payslip, error)
	GetPayslipsByRunID(runID uuid.UUID) ([]domain.Payslip, error)
	SavePayrollBatch(run *domain.PayrollRun, payslips []domain.Payslip) error
	GetAllPayrollRuns(limit, offset int) ([]domain.PayrollRun, error)
	DeletePayrollRun(id uuid.UUID) error

	// Salary Settings management
	SaveEmployeeSalarySetting(setting *domain.EmployeeSalarySetting) error
	DeleteEmployeeSalarySetting(id uuid.UUID) error
}

type payrollRepository struct {
	db *gorm.DB
}

func NewPayrollRepository(db *gorm.DB) PayrollRepository {
	return &payrollRepository{db}
}

func (r *payrollRepository) GetActiveEmployees() ([]uuid.UUID, error) {
	var employeeIDs []uuid.UUID
	err := r.db.Table("employees").Where("employment_status != ?", "TERMINATED").Pluck("id", &employeeIDs).Error
	return employeeIDs, err
}

func (r *payrollRepository) GetEmployeeSnapshotInfo(employeeID uuid.UUID) (string, string) {
	var emp domain.Employee
	// Preload JobPosition to get the job title
	if err := r.db.Preload("JobPosition").Where("id = ?", employeeID).First(&emp).Error; err != nil {
		return "", ""
	}

	jobTitle := ""
	if emp.JobPosition != nil {
		jobTitle = emp.JobPosition.Title
	}

	return jobTitle, emp.PtkpStatus
}

func (r *payrollRepository) GetEmployeeSalarySettings(employeeID uuid.UUID) ([]domain.EmployeeSalarySetting, error) {
	var settings []domain.EmployeeSalarySetting
	err := r.db.Preload("Component").Where("employee_id = ?", employeeID).Find(&settings).Error
	return settings, err
}

func (r *payrollRepository) GetEmployeeAbsentDays(employeeID uuid.UUID, startDate, endDate time.Time) (int, error) {
	var count int64
	err := r.db.Model(&domain.AttendanceLog{}).
		Where("employee_id = ? AND clock_in_time >= ? AND clock_in_time <= ? AND status = ?", employeeID, startDate, endDate, "ABSENT").
		Count(&count).Error
	return int(count), err
}

func (r *payrollRepository) GetMyPayslips(employeeID uuid.UUID) ([]domain.Payslip, error) {
	var payslips []domain.Payslip

	err := r.db.
		Preload("Items").
		Preload("PayrollRun").
		Joins("JOIN payroll_runs ON payroll_runs.id = payslips.payroll_run_id").
		Where("payslips.employee_id = ?", employeeID).
		Order("payroll_runs.payment_schedule DESC").
		Find(&payslips).Error

	return payslips, err
}

func (r *payrollRepository) GetPayslipsByRunID(runID uuid.UUID) ([]domain.Payslip, error) {
	var payslips []domain.Payslip
	err := r.db.
		Preload("Items").
		Preload("Employee").
		Where("payroll_run_id = ?", runID).
		Find(&payslips).Error
	return payslips, err
}

func (r *payrollRepository) SavePayrollBatch(run *domain.PayrollRun, payslips []domain.Payslip) error {
	tx := r.db.Begin()

	if err := tx.Create(run).Error; err != nil {
		tx.Rollback()
		return err
	}

	// Because of GORM's Auto Save (and full struct mapping),
	// saving Payslip automatically saves PayslipItem slices if populated properly and associations are configured.
	if len(payslips) > 0 {
		if err := tx.Create(&payslips).Error; err != nil {
			tx.Rollback()
			return err
		}
	}

	return tx.Commit().Error
}

func (r *payrollRepository) GetAllPayrollRuns(limit, offset int) ([]domain.PayrollRun, error) {
	var runs []domain.PayrollRun
	err := r.db.Order("period_start DESC").Limit(limit).Offset(offset).Find(&runs).Error
	return runs, err
}

func (r *payrollRepository) DeletePayrollRun(id uuid.UUID) error {
	tx := r.db.Begin()

	// 1. Find all Payslips linked to the Run to manually cascade Payslip Items first.
	// Many modern PGSQL DBs do this if configured with FK CASCADE, but GORM sometimes struggles.
	var slipIDs []uuid.UUID
	if err := tx.Model(&domain.Payslip{}).Where("payroll_run_id = ?", id).Pluck("id", &slipIDs).Error; err != nil {
		tx.Rollback()
		return err
	}

	if len(slipIDs) > 0 {
		// 2. Delete Items
		if err := tx.Where("payslip_id IN ?", slipIDs).Delete(&domain.PayslipItem{}).Error; err != nil {
			tx.Rollback()
			return err
		}

		// 3. Delete Payslips
		if err := tx.Where("id IN ?", slipIDs).Delete(&domain.Payslip{}).Error; err != nil {
			tx.Rollback()
			return err
		}
	}

	// 4. Delete Run
	if err := tx.Where("id = ?", id).Delete(&domain.PayrollRun{}).Error; err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

func (r *payrollRepository) SaveEmployeeSalarySetting(setting *domain.EmployeeSalarySetting) error {
	return r.db.Save(setting).Error
}

func (r *payrollRepository) DeleteEmployeeSalarySetting(id uuid.UUID) error {
	return r.db.Delete(&domain.EmployeeSalarySetting{}, id).Error
}

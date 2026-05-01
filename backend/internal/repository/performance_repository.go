package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type PerformanceRepository interface {
	// Regular Employee KPIs
	GetEmployeeKPIs(month, year int) ([]domain.EmployeeKPI, error)
	GetEmployeeKPIByID(id uuid.UUID) (*domain.EmployeeKPI, error)
	GetEmployeeKPIByEmployeeAndPeriod(employeeID uuid.UUID, month, year int) (*domain.EmployeeKPI, error)
	SaveEmployeeKPI(kpi *domain.EmployeeKPI) error

	// Managerial Appraisals
	GetAppraisalsByEmployee(employeeID uuid.UUID) ([]domain.ManagerialAppraisal, error)
	SaveAppraisal(appraisal *domain.ManagerialAppraisal) error

	// Sales KPIs
	GetSalesKPIByEmployeeAndPeriod(employeeID uuid.UUID, month, year int) (*domain.SalesKPI, error)
	GetSalesKPIHistory(employeeID uuid.UUID) ([]domain.SalesKPI, error)
	GetSalesKPIReportByMonth(month, year int) ([]SalesKPIReport, error)
	GetSalesKPIsByMonth(month, year int) ([]domain.SalesKPI, error)
	SaveSalesKPI(kpi *domain.SalesKPI) error

	// Single Employee KPI History
	GetEmployeeKPIHistory(employeeID uuid.UUID) ([]domain.EmployeeKPI, error)

	// Shared utilities (e.g., getting all regular employees)
	GetRegularEmployees() ([]domain.Employee, error)
}

type performanceRepository struct {
	db *gorm.DB
}

func NewPerformanceRepository(db *gorm.DB) PerformanceRepository {
	return &performanceRepository{db}
}

func (r *performanceRepository) GetEmployeeKPIs(month, year int) ([]domain.EmployeeKPI, error) {
	var kpis []domain.EmployeeKPI
	err := r.db.Preload("Employee.User").Preload("Employee.JobPosition").
		Where("period_month = ? AND period_year = ?", month, year).
		Find(&kpis).Error
	return kpis, err
}

func (r *performanceRepository) GetEmployeeKPIByID(id uuid.UUID) (*domain.EmployeeKPI, error) {
	var kpi domain.EmployeeKPI
	err := r.db.Preload("Employee.User").Where("id = ?", id).First(&kpi).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &kpi, nil
}

func (r *performanceRepository) GetEmployeeKPIByEmployeeAndPeriod(employeeID uuid.UUID, month, year int) (*domain.EmployeeKPI, error) {
	var kpi domain.EmployeeKPI
	err := r.db.Where("employee_id = ? AND period_month = ? AND period_year = ?", employeeID, month, year).First(&kpi).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &kpi, nil
}

func (r *performanceRepository) SaveEmployeeKPI(kpi *domain.EmployeeKPI) error {
	return r.db.Save(kpi).Error
}

func (r *performanceRepository) GetAppraisalsByEmployee(employeeID uuid.UUID) ([]domain.ManagerialAppraisal, error) {
	var appraisals []domain.ManagerialAppraisal
	err := r.db.Preload("Manager.User").Where("employee_id = ?", employeeID).Order("review_date DESC").Find(&appraisals).Error
	return appraisals, err
}

func (r *performanceRepository) SaveAppraisal(appraisal *domain.ManagerialAppraisal) error {
	return r.db.Save(appraisal).Error
}

func (r *performanceRepository) GetRegularEmployees() ([]domain.Employee, error) {
	var employees []domain.Employee
	// Simple assumption: non-sales employees (we filter out sales roles if needed, for now get all active)
	err := r.db.Preload("User").Preload("JobPosition").
		Where("employment_status != ?", "TERMINATED").
		Find(&employees).Error
	return employees, err
}

func (r *performanceRepository) GetSalesKPIByEmployeeAndPeriod(employeeID uuid.UUID, month, year int) (*domain.SalesKPI, error) {
	var kpi domain.SalesKPI
	err := r.db.Where("employee_id = ? AND period_month = ? AND period_year = ?", employeeID, month, year).First(&kpi).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &kpi, nil
}

func (r *performanceRepository) GetSalesKPIHistory(employeeID uuid.UUID) ([]domain.SalesKPI, error) {
	var kpis []domain.SalesKPI
	err := r.db.Where("employee_id = ?", employeeID).Order("period_year DESC, period_month DESC").Limit(12).Find(&kpis).Error
	return kpis, err
}

func (r *performanceRepository) GetEmployeeKPIHistory(employeeID uuid.UUID) ([]domain.EmployeeKPI, error) {
	var kpis []domain.EmployeeKPI
	err := r.db.Where("employee_id = ?", employeeID).Order("period_year DESC, period_month DESC").Limit(12).Find(&kpis).Error
	return kpis, err
}

func (r *performanceRepository) SaveSalesKPI(kpi *domain.SalesKPI) error {
	return r.db.Save(kpi).Error
}

type SalesKPIReport struct {
	EmployeeID    uuid.UUID `gorm:"column:employee_id"`
	OmzetLama     float64   `gorm:"column:omzet_lama"`
	OmzetBaru     float64   `gorm:"column:omzet_baru"`
	TotalTokoBaru int       `gorm:"column:total_toko_baru"`
	TotalVisits   int       `gorm:"column:total_visits"`
}

func (r *performanceRepository) GetSalesKPIReportByMonth(month, year int) ([]SalesKPIReport, error) {
	var report []SalesKPIReport
	query := `
		SELECT 
			employee_id,
			SUM(CASE WHEN store_category = 'TOKO_LAMA' THEN total_amount ELSE 0 END) as omzet_lama,
			SUM(CASE WHEN store_category = 'TOKO_BARU' THEN total_amount ELSE 0 END) as omzet_baru,
			COUNT(CASE WHEN store_category = 'TOKO_BARU' THEN 1 END) as total_toko_baru,
			COUNT(DISTINCT visit_id) as total_visits
		FROM sales_transactions
		WHERE status = 'VERIFIED' AND period_month = ? AND period_year = ?
		GROUP BY employee_id
	`
	err := r.db.Raw(query, month, year).Scan(&report).Error
	return report, err
}
 
func (r *performanceRepository) GetSalesKPIsByMonth(month, year int) ([]domain.SalesKPI, error) {
	var kpis []domain.SalesKPI
	err := r.db.Preload("Employee.User").Preload("Employee.JobPosition").
		Where("period_month = ? AND period_year = ?", month, year).
		Find(&kpis).Error
	return kpis, err
}

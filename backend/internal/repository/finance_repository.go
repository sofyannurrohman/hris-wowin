package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type FinanceRepository interface {
	GetRevenueByCompany(companyID uuid.UUID, month, year int) (float64, error)
	GetPayrollByCompany(companyID uuid.UUID, month, year int) (float64, error)
	GetReimbursementByCompany(companyID uuid.UUID, month, year int) (float64, error)
	GetCompanyByID(id uuid.UUID) (*domain.Company, error)
}

type financeRepository struct {
	db *gorm.DB
}

func NewFinanceRepository(db *gorm.DB) FinanceRepository {
	return &financeRepository{db}
}

func (r *financeRepository) GetRevenueByCompany(companyID uuid.UUID, month, year int) (float64, error) {
	var total float64
	err := r.db.Model(&domain.SalesTransaction{}).
		Where("company_id = ? AND period_month = ? AND period_year = ?", companyID, month, year).
		Select("COALESCE(SUM(total_amount), 0)").Scan(&total).Error
	return total, err
}

func (r *financeRepository) GetPayrollByCompany(companyID uuid.UUID, month, year int) (float64, error) {
	var total float64
	err := r.db.Model(&domain.PayrollRun{}).
		Where("company_id = ? AND EXTRACT(MONTH FROM period_start) = ? AND EXTRACT(YEAR FROM period_start) = ?", companyID, month, year).
		Select("COALESCE(SUM(total_payout), 0)").Scan(&total).Error
	return total, err
}

func (r *financeRepository) GetReimbursementByCompany(companyID uuid.UUID, month, year int) (float64, error) {
	var total float64
	err := r.db.Model(&domain.Reimbursement{}).
		Joins("JOIN employees ON employees.id = reimbursements.employee_id").
		Where("employees.company_id = ? AND status = ? AND EXTRACT(MONTH FROM reimbursements.created_at) = ? AND EXTRACT(YEAR FROM reimbursements.created_at) = ?", 
			companyID, domain.ReimbursementApproved, month, year).
		Select("COALESCE(SUM(reimbursements.amount), 0)").Scan(&total).Error
	return total, err
}

func (r *financeRepository) GetCompanyByID(id uuid.UUID) (*domain.Company, error) {
	var company domain.Company
	err := r.db.First(&company, id).Error
	return &company, err
}

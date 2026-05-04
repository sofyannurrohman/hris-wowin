package usecase

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type FinanceUsecase interface {
	GetProfitLossReport(companyID uuid.UUID, month, year int) (*domain.ProfitLossReport, error)
}

type financeUsecase struct {
	repo repository.FinanceRepository
}

func NewFinanceUsecase(repo repository.FinanceRepository) FinanceUsecase {
	return &financeUsecase{repo}
}

func (u *financeUsecase) GetProfitLossReport(companyID uuid.UUID, month, year int) (*domain.ProfitLossReport, error) {
	company, err := u.repo.GetCompanyByID(companyID)
	if err != nil {
		return nil, err
	}

	revenue, err := u.repo.GetRevenueByCompany(companyID, month, year)
	if err != nil {
		return nil, err
	}

	payroll, err := u.repo.GetPayrollByCompany(companyID, month, year)
	if err != nil {
		return nil, err
	}

	reimbursements, err := u.repo.GetReimbursementByCompany(companyID, month, year)
	if err != nil {
		return nil, err
	}

	// For simple P&L, assume 70% of revenue is COGS if not tracked individually
	cogs := revenue * 0.70 

	report := &domain.ProfitLossReport{
		CompanyID:     companyID,
		CompanyName:   company.Name,
		PeriodMonth:   month,
		PeriodYear:    year,
		TotalRevenue:  revenue,
		TotalCOGS:     cogs,
		TotalPayroll:  payroll,
		TotalExpenses: reimbursements, 
		GrossProfit:   revenue - cogs,
		NetProfit:     (revenue - cogs) - (payroll + reimbursements),
	}

	return report, nil
}

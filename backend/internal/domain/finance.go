package domain

import (
	"github.com/google/uuid"
)

type ProfitLossReport struct {
	CompanyID      uuid.UUID `json:"company_id"`
	CompanyName    string    `json:"company_name"`
	PeriodMonth    int       `json:"period_month"`
	PeriodYear     int       `json:"period_year"`
	
	// Revenue
	TotalRevenue   float64   `json:"total_revenue"`
	
	// Expenses
	TotalCOGS      float64   `json:"total_cogs"`       // Cost of Goods Sold
	TotalPayroll   float64   `json:"total_payroll"`    // Gaji Karyawan
	TotalExpenses  float64   `json:"total_expenses"`   // Other operational costs
	
	// Profit
	GrossProfit    float64   `json:"gross_profit"`     // Revenue - COGS
	NetProfit      float64   `json:"net_profit"`       // Gross - (Payroll + Expenses)
}

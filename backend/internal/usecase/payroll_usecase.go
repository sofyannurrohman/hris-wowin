package usecase

import (
	"bytes"
	"encoding/csv"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type PayrollUseCase interface {
	GeneratePayroll(companyID uuid.UUID, req GeneratePayrollRequest) (*domain.PayrollRun, error)
	GetMyPayslipHistory(userID uuid.UUID) ([]domain.MyPayslipResponse, error)
	ExportPayrollRunCSV(payrollRunID uuid.UUID) ([]byte, error)
	GetAllPayrollRuns(page, limit int) ([]domain.PayrollRun, error)
	DeletePayrollRun(id uuid.UUID) error
}

type payrollUseCase struct {
	repo         repository.PayrollRepository
	employeeRepo repository.EmployeeRepository
}

func NewPayrollUseCase(repo repository.PayrollRepository, employeeRepo repository.EmployeeRepository) PayrollUseCase {
	return &payrollUseCase{repo, employeeRepo}
}

type GeneratePayrollRequest struct {
	PeriodStart     string `json:"period_start" binding:"required"` // YYYY-MM-DD
	PeriodEnd       string `json:"period_end" binding:"required"`
	PaymentSchedule string `json:"payment_schedule" binding:"required"`
}

func (u *payrollUseCase) GeneratePayroll(companyID uuid.UUID, req GeneratePayrollRequest) (*domain.PayrollRun, error) {
	layout := "2006-01-02"
	start, err := time.Parse(layout, req.PeriodStart)
	if err != nil {
		return nil, errors.New("invalid period_start format, expected YYYY-MM-DD")
	}
	end, err := time.Parse(layout, req.PeriodEnd)
	if err != nil {
		return nil, errors.New("invalid period_end format, expected YYYY-MM-DD")
	}
	payment, err := time.Parse(layout, req.PaymentSchedule)
	if err != nil {
		return nil, errors.New("invalid payment_schedule format, expected YYYY-MM-DD")
	}

	if end.Before(start) {
		return nil, errors.New("period_end cannot be before period_start")
	}

	payrollRunID := uuid.New()
	var grandTotalPayout float64
	var allPayslips []domain.Payslip

	employeeIDs, err := u.repo.GetActiveEmployees()
	if err != nil {
		return nil, errors.New("failed to retrieve active employees")
	}

	for _, empID := range employeeIDs {
		settings, err := u.repo.GetEmployeeSalarySettings(empID)
		if err != nil || len(settings) == 0 {
			continue // Skip employee with no salary settings
		}

		var totalAllowance, totalDeduction, basicSalary float64
		var payslipItems []domain.PayslipItem

		for _, setting := range settings {
			if setting.Component == nil {
				continue
			}

			item := domain.PayslipItem{
				ID:            uuid.New(),
				PayslipID:     uuid.Nil, // Will be linked automatically by GORM relations or we set it manually below
				ComponentName: setting.Component.Name,
				Amount:        setting.Amount,
				Type:          setting.Component.Type,
			}

			if setting.Component.Type == "EARNING" {
				if setting.Component.Name == "Gaji Pokok" || setting.Component.Name == "Basic Salary" {
					basicSalary = setting.Amount
				} else {
					totalAllowance += setting.Amount
				}
			} else if setting.Component.Type == "DEDUCTION" {
				totalDeduction += setting.Amount
			}

			// Optional: Handle "BENEFIT" like insurance paid by company if needed, not affecting THP directly unless specified.
			payslipItems = append(payslipItems, item)
		}

		takeHomePay := (basicSalary + totalAllowance) - totalDeduction
		grandTotalPayout += takeHomePay

		jobTitle, ptkp := u.repo.GetEmployeeSnapshotInfo(empID)

		payslipID := uuid.New()

		// Link proper ID to items manually for safety just in case
		for idx := range payslipItems {
			payslipItems[idx].PayslipID = payslipID
		}

		slip := domain.Payslip{
			ID:                 payslipID,
			PayrollRunID:       payrollRunID,
			EmployeeID:         empID,
			SnapshotJobTitle:   jobTitle,
			SnapshotPtkpStatus: ptkp,
			BasicSalary:        basicSalary,
			TotalAllowance:     totalAllowance,
			TotalDeduction:     totalDeduction,
			TakeHomePay:        takeHomePay,
			Items:              payslipItems,
		}

		allPayslips = append(allPayslips, slip)
	}

	if len(allPayslips) == 0 {
		return nil, errors.New("no employees with salary components were found to process")
	}

	payrollRun := &domain.PayrollRun{
		ID:              payrollRunID,
		CompanyID:       &companyID, // Assign to the admin's company requesting it
		PeriodStart:     start,
		PeriodEnd:       end,
		PaymentSchedule: &payment,
		Status:          "PROCESSED",
		TotalPayout:     &grandTotalPayout,
	}

	err = u.repo.SavePayrollBatch(payrollRun, allPayslips)
	if err != nil {
		return nil, errors.New("fatal sequence error saving payroll batch: " + err.Error())
	}

	return payrollRun, nil
}

func (u *payrollUseCase) GetMyPayslipHistory(userID uuid.UUID) ([]domain.MyPayslipResponse, error) {
	// 1. Resolve Employee from UserID
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return nil, err
	}
	if employee == nil {
		return nil, errors.New("employee record not found for this user")
	}

	payslips, err := u.repo.GetMyPayslips(employee.ID)
	if err != nil {
		return nil, errors.New("failed to retrieve payslip data")
	}

	var response []domain.MyPayslipResponse
	if payslips == nil {
		return []domain.MyPayslipResponse{}, nil
	}

	for _, slip := range payslips {
		var earnings []domain.PayslipItemDetail
		var deductions []domain.PayslipItemDetail

		for _, item := range slip.Items {
			detail := domain.PayslipItemDetail{
				Name:   item.ComponentName,
				Amount: item.Amount,
			}

			if item.Type == "EARNING" {
				earnings = append(earnings, detail)
			} else if item.Type == "DEDUCTION" {
				deductions = append(deductions, detail)
			}
		}

		if earnings == nil {
			earnings = []domain.PayslipItemDetail{}
		}
		if deductions == nil {
			deductions = []domain.PayslipItemDetail{}
		}

		periodStr := ""
		paymentDate := ""
		if slip.PayrollRun != nil {
			periodStr = slip.PayrollRun.PeriodStart.Format("02 Jan 2006") + " - " + slip.PayrollRun.PeriodEnd.Format("02 Jan 2006")
			if slip.PayrollRun.PaymentSchedule != nil {
				paymentDate = slip.PayrollRun.PaymentSchedule.Format("2006-01-02")
			}
		}

		res := domain.MyPayslipResponse{
			ID:             slip.ID.String(),
			Period:         periodStr,
			PaymentDate:    paymentDate,
			JobTitle:       slip.SnapshotJobTitle,
			BasicSalary:    slip.BasicSalary,
			TotalAllowance: slip.TotalAllowance,
			TotalDeduction: slip.TotalDeduction,
			TakeHomePay:    slip.TakeHomePay,
			Earnings:       earnings,
			Deductions:     deductions,
		}

		response = append(response, res)
	}

	if response == nil {
		response = []domain.MyPayslipResponse{}
	}

	return response, nil
}

func (u *payrollUseCase) ExportPayrollRunCSV(payrollRunID uuid.UUID) ([]byte, error) {
	payslips, err := u.repo.GetPayslipsByRunID(payrollRunID)
	if err != nil {
		return nil, errors.New("failed to retrieve payslips for the given run ID")
	}

	if len(payslips) == 0 {
		return nil, errors.New("no payslips found for this payroll run")
	}

	var buf bytes.Buffer
	writer := csv.NewWriter(&buf)

	// CSV Header (MCM Mandiri / BCA standard format)
	header := []string{"No", "Account_Number", "Account_Name", "Bank_Name", "Amount", "Description"}
	if err := writer.Write(header); err != nil {
		return nil, errors.New("failed to write CSV header")
	}

	for i, slip := range payslips {
		emp := slip.Employee
		if emp == nil {
			continue // Avoid panic if relation fails to load
		}

		desc := fmt.Sprintf("Gaji %s", emp.FirstName)
		amountStr := fmt.Sprintf("%.2f", slip.TakeHomePay)

		row := []string{
			fmt.Sprintf("%d", i+1),
			emp.BankAccountNumber,
			emp.AccountHolderName,
			emp.BankName,
			amountStr,
			desc,
		}

		if err := writer.Write(row); err != nil {
			return nil, errors.New("failed to write CSV row")
		}
	}

	writer.Flush()
	if err := writer.Error(); err != nil {
		return nil, errors.New("error flushing CSV writer")
	}

	return buf.Bytes(), nil
}

func (u *payrollUseCase) GetAllPayrollRuns(page, limit int) ([]domain.PayrollRun, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	offset := (page - 1) * limit
	return u.repo.GetAllPayrollRuns(limit, offset)
}

func (u *payrollUseCase) DeletePayrollRun(id uuid.UUID) error {
	return u.repo.DeletePayrollRun(id)
}

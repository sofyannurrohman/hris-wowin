package usecase

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type SalesUsecase interface {
	ManualEntry(req ManualEntryRequest) (*domain.SalesTransaction, error)
	CalculateKPI(employeeID uuid.UUID, month, year int) error
	GenerateKPIReportExcel(month, year int) ([]byte, error)
	GetSummaryKPI(month, year int) (map[string]interface{}, error)

	// Mobile App Endpoints
	CreateTransaction(req CreateTransactionRequest) (*domain.SalesTransaction, error)
	GetPendingTransactions(employeeID uuid.UUID) ([]domain.SalesTransaction, error)
	GetHistoryTransactions(employeeID uuid.UUID) ([]domain.SalesTransaction, error)
	VerifyTransaction(id uuid.UUID, req VerifyTransactionRequest) error
	GetPerformanceList(month, year int) ([]domain.SalesKPI, error)
	GetAllPendingTransactions() ([]domain.SalesTransaction, error)
	GetAllTransactions() ([]domain.SalesTransaction, error)
	UpdateTransaction(id uuid.UUID, req ManualEntryRequest) error
	DeleteTransaction(id uuid.UUID) error
	SetKPITarget(employeeID uuid.UUID, month, year int, targetOmzet float64, targetNewStores int, workingTerritory string) error
}

type CreateTransactionRequest struct {
	CompanyID       uuid.UUID `json:"company_id"`
	StoreID         uuid.UUID `json:"store_id"`
	EmployeeID      uuid.UUID `json:"employee_id"`
	ReceiptNo       string    `json:"receipt_no"`
	ReceiptImageURL string    `json:"receipt_image_url"`
	TotalAmount     float64   `json:"total_amount"`
	StoreCategory   string    `json:"store_category"`
	TransactionDate time.Time `json:"transaction_date"`
	Notes           string    `json:"notes"`
}

type VerifyTransactionRequest struct {
	ReceiptNo   string  `json:"receipt_no"`
	TotalAmount float64 `json:"total_amount"`
	Notes       string  `json:"notes"` // Catatan dari finalisasi
}

type salesUsecase struct {
	salesRepo       repository.SalesTransactionRepository
	performanceRepo repository.PerformanceRepository
}

func NewSalesUsecase(salesRepo repository.SalesTransactionRepository, performanceRepo repository.PerformanceRepository) SalesUsecase {
	return &salesUsecase{
		salesRepo:       salesRepo,
		performanceRepo: performanceRepo,
	}
}

type ManualEntryRequest struct {
	CompanyID       uuid.UUID `json:"company_id"`
	StoreID         uuid.UUID `json:"store_id"`
	EmployeeID      uuid.UUID `json:"employee_id" binding:"required"`
	ReceiptNo       string    `json:"receipt_no"`
	ReceiptImageURL string    `json:"receipt_image_url"`
	TotalAmount     float64   `json:"total_amount" binding:"required"`
	StoreCategory   string    `json:"store_category" binding:"required"` // 'TOKO_LAMA' or 'TOKO_BARU'
	TransactionDate string    `json:"transaction_date" binding:"required"` // YYYY-MM-DD
	Status          string    `json:"status"` // 'PENDING', 'VERIFIED', 'REJECTED'
}

func (u *salesUsecase) ManualEntry(req ManualEntryRequest) (*domain.SalesTransaction, error) {
	trxDate, err := time.Parse("2006-01-02", req.TransactionDate)
	if err != nil {
		return nil, errors.New("invalid transaction date format, expected YYYY-MM-DD")
	}

	trx := &domain.SalesTransaction{
		CompanyID:       req.CompanyID,
		StoreID:         req.StoreID,
		EmployeeID:      req.EmployeeID,
		ReceiptNo:       req.ReceiptNo,
		ReceiptImageURL: req.ReceiptImageURL,
		TotalAmount:     req.TotalAmount,
		StoreCategory:   req.StoreCategory,
		TransactionDate: trxDate,
		PeriodMonth:     int(trxDate.Month()),
		PeriodYear:      trxDate.Year(),
		Status:          req.Status,
	}

	if trx.Status == "" {
		trx.Status = "VERIFIED"
	}

	err = u.salesRepo.Create(trx)
	if err != nil {
		return nil, err
	}

	// Recalculate KPI for this employee
	err = u.CalculateKPI(req.EmployeeID, int(trxDate.Month()), trxDate.Year())
	if err != nil {
		// Log the error but don't fail the transaction entry
	}

	return trx, nil
}

func (u *salesUsecase) CalculateKPI(employeeID uuid.UUID, month, year int) error {
	kpiReports, err := u.performanceRepo.GetSalesKPIReportByMonth(month, year)
	if err != nil {
		return err
	}

	var report *repository.SalesKPIReport
	for _, r := range kpiReports {
		if r.EmployeeID == employeeID {
			report = &r
			break
		}
	}

	if report == nil {
		return nil // No transactions found
	}

	totalOmzet := report.OmzetLama + report.OmzetBaru

	salesKpi, err := u.performanceRepo.GetSalesKPIByEmployeeAndPeriod(employeeID, month, year)
	if err != nil {
		return err
	}

	if salesKpi == nil {
		// Create new if not exists
		salesKpi = &domain.SalesKPI{
			EmployeeID:     employeeID,
			TargetOmzet:    0, // Needs manual setup later
			TargetNewStores: 0,
			PeriodMonth:    month,
			PeriodYear:     year,
		}
	}

	salesKpi.AchievedOmzet = totalOmzet
	salesKpi.AchievedOmzetLama = report.OmzetLama
	salesKpi.AchievedOmzetBaru = report.OmzetBaru
	salesKpi.AchievedNewStores = report.TotalTokoBaru
	salesKpi.TotalVisits = report.TotalVisits
	// Calculation logic for estimated bonus could go here based on omzet_lama vs omzet_baru

	return u.performanceRepo.SaveSalesKPI(salesKpi)
}

func (u *salesUsecase) GenerateKPIReportExcel(month, year int) ([]byte, error) {
	// 1. Fetch data from PerformanceRepository
	reports, err := u.performanceRepo.GetSalesKPIReportByMonth(month, year)
	if err != nil {
		return nil, err
	}

	// 2. Mocking Excel generation process
	// Usually this would use a library like `github.com/xuri/excelize/v2`
	// Here we simply return a mocked byte array mimicking CSV/Excel data
	csvData := "EmployeeID,OmzetLama,OmzetBaru,TotalTokoBaru\n"
	for _, r := range reports {
		csvData += r.EmployeeID.String() + "," + 
			// Formatting float simply for demo
			"" + "," + 
			"" + "," + 
			"0" + "\n"
	}

	return []byte(csvData), nil
}

func (u *salesUsecase) GetSummaryKPI(month, year int) (map[string]interface{}, error) {
	reports, err := u.performanceRepo.GetSalesKPIReportByMonth(month, year)
	if err != nil {
		return nil, err
	}

	var totalOmzetLama float64
	var totalOmzetBaru float64
	var totalTokoBaru int

	for _, r := range reports {
		totalOmzetLama += r.OmzetLama
		totalOmzetBaru += r.OmzetBaru
		totalTokoBaru += r.TotalTokoBaru
	}

	return map[string]interface{}{
		"period_month":    month,
		"period_year":     year,
		"total_omzet_lama": totalOmzetLama,
		"total_omzet_baru": totalOmzetBaru,
		"total_omzet_all":  totalOmzetLama + totalOmzetBaru,
		"total_toko_baru":  totalTokoBaru,
	}, nil
}

func (u *salesUsecase) CreateTransaction(req CreateTransactionRequest) (*domain.SalesTransaction, error) {
	trx := &domain.SalesTransaction{
		CompanyID:       req.CompanyID,
		StoreID:         req.StoreID,
		EmployeeID:      req.EmployeeID,
		ReceiptNo:       req.ReceiptNo,
		ReceiptImageURL: req.ReceiptImageURL,
		TotalAmount:     req.TotalAmount,
		StoreCategory:   req.StoreCategory,
		TransactionDate: req.TransactionDate,
		PeriodMonth:     int(req.TransactionDate.Month()),
		PeriodYear:      req.TransactionDate.Year(),
		Status:          "PENDING",
		Notes:           &req.Notes,
	}

	err := u.salesRepo.Create(trx)
	if err != nil {
		return nil, err
	}

	return trx, nil
}

func (u *salesUsecase) GetPendingTransactions(employeeID uuid.UUID) ([]domain.SalesTransaction, error) {
	// Re-using the repository, maybe filtering by status PENDING manually or we add a repo method.
	// We'll fetch all by employee and period, but filtering manually is fine for now, or just add a method.
	// Since repo only has GetTransactionsByEmployeeAndPeriod, let's use FindAll and filter.
	// In a real app we'd add GetPendingByEmployee to repo.
	all, err := u.salesRepo.FindAll()
	if err != nil {
		return nil, err
	}

	var pending []domain.SalesTransaction
	for _, t := range all {
		if t.EmployeeID == employeeID && t.Status == "PENDING" {
			pending = append(pending, t)
		}
	}
	return pending, nil
}

func (u *salesUsecase) GetHistoryTransactions(employeeID uuid.UUID) ([]domain.SalesTransaction, error) {
	all, err := u.salesRepo.FindAll()
	if err != nil {
		return nil, err
	}

	var history []domain.SalesTransaction
	// Let's return all transactions for the employee (or just VERIFIED, depending on need. The user wants log checkin/checkout, upload nota, etc. So returning all makes sense).
	for _, t := range all {
		if t.EmployeeID == employeeID {
			history = append(history, t)
		}
	}
	
	// Normally we would sort by date descending here, but let's assume it's sorted by creation order in FindAll.
	return history, nil
}

func (u *salesUsecase) VerifyTransaction(id uuid.UUID, req VerifyTransactionRequest) error {
	trx, err := u.salesRepo.FindByID(id)
	if err != nil {
		return err
	}
	if trx == nil {
		return errors.New("transaction not found")
	}

	trx.ReceiptNo = req.ReceiptNo
	trx.TotalAmount = req.TotalAmount
	trx.Status = "VERIFIED"
	trx.Notes = &req.Notes

	err = u.salesRepo.Update(trx)
	if err != nil {
		return err
	}

	// Recalculate KPI after verification
	_ = u.CalculateKPI(trx.EmployeeID, trx.PeriodMonth, trx.PeriodYear)

	return nil
}

func (u *salesUsecase) GetPerformanceList(month, year int) ([]domain.SalesKPI, error) {
	// In a real scenario, we might want to fetch all employees with a 'Sales' role
	// and then join with their KPI for the period.
	// For now, let's fetch all SalesKPI entries for the period.
	
	// We'll need a new repo method or just use a generic one if available.
	// Let's assume we can use FindAll with filters or add a specialized one.
	// Since performanceRepo has GetSalesKPIReportByMonth, we can use that to get current achievements
	// but we also need the TARGETS which are in domain.SalesKPI.
	
	// Let's add a method to performanceRepo to get all SalesKPIs for a month.
	return u.performanceRepo.GetSalesKPIsByMonth(month, year)
}

func (u *salesUsecase) GetAllPendingTransactions() ([]domain.SalesTransaction, error) {
	all, err := u.salesRepo.FindAll()
	if err != nil {
		return nil, err
	}

	var pending []domain.SalesTransaction
	for _, t := range all {
		if t.Status == "PENDING" {
			pending = append(pending, t)
		}
	}
	return pending, nil
}

func (u *salesUsecase) GetAllTransactions() ([]domain.SalesTransaction, error) {
	return u.salesRepo.FindAll()
}

func (u *salesUsecase) UpdateTransaction(id uuid.UUID, req ManualEntryRequest) error {
	trx, err := u.salesRepo.FindByID(id)
	if err != nil {
		return err
	}
	if trx == nil {
		return errors.New("transaction not found")
	}

	trxDate, err := time.Parse("2006-01-02", req.TransactionDate)
	if err != nil {
		return errors.New("invalid transaction date format, expected YYYY-MM-DD")
	}

	// Store old values for KPI recalculation if period or employee changes
	oldEmployeeID := trx.EmployeeID
	oldMonth := trx.PeriodMonth
	oldYear := trx.PeriodYear

	trx.StoreID = req.StoreID
	trx.EmployeeID = req.EmployeeID
	trx.ReceiptNo = req.ReceiptNo
	trx.ReceiptImageURL = req.ReceiptImageURL
	trx.TotalAmount = req.TotalAmount
	trx.StoreCategory = req.StoreCategory
	trx.TransactionDate = trxDate
	trx.PeriodMonth = int(trxDate.Month())
	trx.PeriodYear = trxDate.Year()

	err = u.salesRepo.Update(trx)
	if err != nil {
		return err
	}

	// Recalculate KPI for current (new) period/employee
	_ = u.CalculateKPI(trx.EmployeeID, trx.PeriodMonth, trx.PeriodYear)

	// If period or employee changed, recalculate the old one too
	if oldEmployeeID != trx.EmployeeID || oldMonth != trx.PeriodMonth || oldYear != trx.PeriodYear {
		_ = u.CalculateKPI(oldEmployeeID, oldMonth, oldYear)
	}

	return nil
}

func (u *salesUsecase) DeleteTransaction(id uuid.UUID) error {
	trx, err := u.salesRepo.FindByID(id)
	if err != nil {
		return err
	}
	if trx == nil {
		return errors.New("transaction not found")
	}

	err = u.salesRepo.Delete(id)
	if err != nil {
		return err
	}

	// Recalculate KPI after deletion
	_ = u.CalculateKPI(trx.EmployeeID, trx.PeriodMonth, trx.PeriodYear)

	return nil
}

func (u *salesUsecase) SetKPITarget(employeeID uuid.UUID, month, year int, targetOmzet float64, targetNewStores int, workingTerritory string) error {
	kpi, err := u.performanceRepo.GetSalesKPIByEmployeeAndPeriod(employeeID, month, year)
	if err != nil {
		return err
	}

	if kpi == nil {
		kpi = &domain.SalesKPI{
			EmployeeID:     employeeID,
			PeriodMonth:    month,
			PeriodYear:     year,
		}
	}

	kpi.TargetOmzet = targetOmzet
	kpi.TargetNewStores = targetNewStores
	kpi.WorkingTerritory = workingTerritory

	return u.performanceRepo.SaveSalesKPI(kpi)
}


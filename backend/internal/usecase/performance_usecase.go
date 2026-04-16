package usecase

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type PerformanceUseCase interface {
	GetEmployeeKPIs(month, year int) ([]domain.EmployeeKPI, error)
	UpdateEmployeeKPI(id uuid.UUID, productivityScore float64) error
	EvaluateAndAppraise(req EvaluateAppraisalRequest) error
	GetAppraisals(employeeID uuid.UUID) ([]domain.ManagerialAppraisal, error)

	// Employee Self-View
	GetMyPerformance(employeeID uuid.UUID, month, year int) (map[string]interface{}, error)
	GetMyPerformanceHistory(employeeID uuid.UUID) ([]map[string]interface{}, error)
}

type performanceUseCase struct {
	repo repository.PerformanceRepository
}

func NewPerformanceUseCase(repo repository.PerformanceRepository) PerformanceUseCase {
	return &performanceUseCase{repo}
}

func (u *performanceUseCase) GetEmployeeKPIs(month, year int) ([]domain.EmployeeKPI, error) {
	// First, fetch existing KPIs
	existingKPIs, err := u.repo.GetEmployeeKPIs(month, year)
	if err != nil {
		return nil, err
	}

	// Map existing by EmployeeID
	kpiMap := make(map[uuid.UUID]bool)
	for _, kpi := range existingKPIs {
		kpiMap[kpi.EmployeeID] = true
	}

	// Fetch all regular employees
	employees, err := u.repo.GetRegularEmployees()
	if err != nil {
		return nil, err
	}

	// Auto-generate missing KPIs
	var finalKPIs []domain.EmployeeKPI
	finalKPIs = append(finalKPIs, existingKPIs...)

	for _, emp := range employees {
		if !kpiMap[emp.ID] {
			// Create dummy entry
			newKPI := domain.EmployeeKPI{
				ID:                uuid.New(),
				EmployeeID:        emp.ID,
				AttendanceScore:   100, // Default optimistic
				ProductivityScore: 0,
				FinalScore:        0,
				PeriodMonth:       month,
				PeriodYear:        year,
				Employee:          &emp,
			}
			err = u.repo.SaveEmployeeKPI(&newKPI)
			if err == nil {
				finalKPIs = append(finalKPIs, newKPI)
			}
		}
	}

	return finalKPIs, nil
}

func (u *performanceUseCase) UpdateEmployeeKPI(id uuid.UUID, productivityScore float64) error {
	kpi, err := u.repo.GetEmployeeKPIByID(id)
	if err != nil {
		return err
	}
	if kpi == nil {
		return nil // Or return a "Not Found" error
	}

	kpi.ProductivityScore = productivityScore
	// Example calculation logic: 40% Attendance, 60% Productivity
	kpi.FinalScore = (kpi.AttendanceScore * 0.4) + (productivityScore * 0.6)

	return u.repo.SaveEmployeeKPI(kpi)
}

type EvaluateAppraisalRequest struct {
	EmployeeID uuid.UUID `json:"employee_id" binding:"required"`
	ManagerID  uuid.UUID `json:"manager_id" binding:"required"`
	Notes      string    `json:"notes" binding:"required"`
	Rating     float64   `json:"rating" binding:"required"`
}

func (u *performanceUseCase) EvaluateAndAppraise(req EvaluateAppraisalRequest) error {
	appraisal := &domain.ManagerialAppraisal{
		ID:          uuid.New(),
		EmployeeID:  req.EmployeeID,
		ManagerID:   req.ManagerID,
		ReviewNotes: req.Notes,
		Rating:      req.Rating,
		ReviewDate:  time.Now(),
	}

	return u.repo.SaveAppraisal(appraisal)
}

func (u *performanceUseCase) GetAppraisals(employeeID uuid.UUID) ([]domain.ManagerialAppraisal, error) {
	return u.repo.GetAppraisalsByEmployee(employeeID)
}

func (u *performanceUseCase) GetMyPerformance(employeeID uuid.UUID, month, year int) (map[string]interface{}, error) {
	// 1. Try to get EmployeeKPI
	regKPI, _ := u.repo.GetEmployeeKPIByEmployeeAndPeriod(employeeID, month, year)
	
	// 2. Try to get SalesKPI
	salesKPI, _ := u.repo.GetSalesKPIByEmployeeAndPeriod(employeeID, month, year)

	// 3. Compose response
	res := map[string]interface{}{
		"period": fmt.Sprintf("%04d-%02d", year, month),
		"status": "DRAFT",
	}

	if salesKPI != nil {
		res["type"] = "SALES"
		res["achievement_percentage"] = (salesKPI.AchievedOmzet / salesKPI.TargetOmzet) * 100
		res["final_score"] = res["achievement_percentage"]
		res["bonus"] = salesKPI.EstimatedBonus
		res["items"] = []map[string]interface{}{
			{"label": "Omzet Target", "score": salesKPI.TargetOmzet, "weight": "100%"},
			{"label": "Pencapaian", "score": salesKPI.AchievedOmzet, "weight": ""},
		}
	} else if regKPI != nil {
		res["type"] = "INTERNAL"
		res["final_score"] = regKPI.FinalScore
		res["items"] = []map[string]interface{}{
			{"label": "Kehadiran", "score": regKPI.AttendanceScore, "weight": "40%"},
			{"label": "Produktivitas", "score": regKPI.ProductivityScore, "weight": "60%"},
		}
	}

	return res, nil
}

func (u *performanceUseCase) GetMyPerformanceHistory(employeeID uuid.UUID) ([]map[string]interface{}, error) {
	regHistory, _ := u.repo.GetEmployeeKPIHistory(employeeID)
	salesHistory, _ := u.repo.GetSalesKPIHistory(employeeID)

	var history []map[string]interface{}

	for _, k := range regHistory {
		history = append(history, map[string]interface{}{
			"period":      fmt.Sprintf("%04d-%02d", k.PeriodYear, k.PeriodMonth),
			"final_score": k.FinalScore,
			"type":        "INTERNAL",
		})
	}

	for _, k := range salesHistory {
		history = append(history, map[string]interface{}{
			"period":      fmt.Sprintf("%04d-%02d", k.PeriodYear, k.PeriodMonth),
			"final_score": (k.AchievedOmzet / k.TargetOmzet) * 100,
			"type":        "SALES",
		})
	}

	return history, nil
}

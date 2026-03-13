package http

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

type PayrollHandler struct {
	payrollUseCase usecase.PayrollUseCase
}

func NewPayrollHandler(payrollUseCase usecase.PayrollUseCase) *PayrollHandler {
	return &PayrollHandler{payrollUseCase}
}

func (h *PayrollHandler) SetupRoutes(router *gin.RouterGroup) {
	payroll := router.Group("/payroll")
	// For general Employee Self Service (ESS)
	payroll.GET("/my-payslip", h.GetMyPayslips)

	// Only HR Admins and SuperAdmins can run the payroll batch engine
	adminPayroll := payroll.Group("")
	adminPayroll.Use(RoleMiddleware(string(domain.RoleSuperAdmin), string(domain.RoleHRAdmin)))
	{
		adminPayroll.GET("/all", h.GetAllPayrollRuns)
		adminPayroll.POST("/generate", h.RunPayrollBatch)
		adminPayroll.GET("/:id/export", h.ExportPayrollRunCSV)
		adminPayroll.DELETE("/:id", h.DeletePayrollRun)
	}
}

func (h *PayrollHandler) RunPayrollBatch(c *gin.Context) {
	var req usecase.GeneratePayrollRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid input for payroll period: "+err.Error())
		return
	}

	// Because only admins can execute this, we use the company ID from context if multitenant,
	// Assuming mono-tenant for now, we'll try to extract the user's company ID (if available in token claims).
	companyIDStr, exists := c.Get("companyID")
	var companyID uuid.UUID
	if exists && companyIDStr != "" {
		parsed, err := uuid.Parse(companyIDStr.(string))
		if err == nil {
			companyID = parsed
		}
	} else {
		// Fallback nil / empty UUID if not configured inside the token claim
		companyID = uuid.Nil
	}

	result, err := h.payrollUseCase.GeneratePayroll(companyID, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Payroll successfully processed",
		"data": map[string]interface{}{
			"payroll_run_id": result.ID,
			"total_payout":   result.TotalPayout,
			"status":         result.Status,
		},
	})
}

func (h *PayrollHandler) GetMyPayslips(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	result, err := h.payrollUseCase.GetMyPayslipHistory(userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Berhasil mengambil riwayat slip gaji",
		"data":    result,
	})
}

func (h *PayrollHandler) ExportPayrollRunCSV(c *gin.Context) {
	runIDStr := c.Param("id")
	runID, err := uuid.Parse(runIDStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid Run ID format")
		return
	}

	csvData, err := h.payrollUseCase.ExportPayrollRunCSV(runID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	c.Header("Content-Type", "text/csv")
	c.Header("Content-Disposition", fmt.Sprintf("attachment;filename=payroll_export_%s.csv", runIDStr))
	c.Data(http.StatusOK, "text/csv", csvData)
}

func (h *PayrollHandler) GetAllPayrollRuns(c *gin.Context) {
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "10")

	var page, limit int
	fmt.Sscanf(pageStr, "%d", &page)
	fmt.Sscanf(limitStr, "%d", &limit)

	runs, err := h.payrollUseCase.GetAllPayrollRuns(page, limit)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get payroll history: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Payroll history fetched successfully", runs)
}

func (h *PayrollHandler) DeletePayrollRun(c *gin.Context) {
	idParam := c.Param("id")
	runID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid Payroll Run ID")
		return
	}

	if err := h.payrollUseCase.DeletePayrollRun(runID); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to delete payroll run: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Payroll run deleted successfully", nil)
}

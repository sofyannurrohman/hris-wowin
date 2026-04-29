package http

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type SalesHandler struct {
	salesUsecase    usecase.SalesUsecase
	employeeUseCase usecase.EmployeeUsecase
}

func NewSalesHandler(salesUsecase usecase.SalesUsecase, employeeUseCase usecase.EmployeeUsecase) *SalesHandler {
	return &SalesHandler{
		salesUsecase:    salesUsecase,
		employeeUseCase: employeeUseCase,
	}
}

func (h *SalesHandler) RegisterRoutes(router *gin.RouterGroup) {
	sales := router.Group("/admin/sales")
	{
		sales.POST("/manual-entry", h.ManualEntry)
		sales.GET("/reports/excel", h.ExportExcel)
		sales.GET("/reports/summary", h.GetSummary)
	}
}

func (h *SalesHandler) SetupMobileRoutes(router *gin.RouterGroup) {
	sales := router.Group("/sales")
	{
		sales.POST("/transactions", h.CreateTransaction)
		sales.GET("/transactions/pending", h.GetPendingTransactions)
		sales.GET("/transactions/history", h.GetHistoryTransactions)
		sales.PATCH("/transactions/:id/verify", h.VerifyTransaction)
	}
}

func (h *SalesHandler) ManualEntry(c *gin.Context) {
	var req usecase.ManualEntryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	trx, err := h.salesUsecase.ManualEntry(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Manual entry successful",
		"data":    trx,
	})
}


func (h *SalesHandler) ExportExcel(c *gin.Context) {
	monthStr := c.DefaultQuery("month", "1")
	yearStr := c.DefaultQuery("year", "2024")
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	data, err := h.salesUsecase.GenerateKPIReportExcel(month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Header("Content-Disposition", "attachment; filename=sales_kpi_report.csv")
	c.Data(http.StatusOK, "text/csv", data)
}

func (h *SalesHandler) GetSummary(c *gin.Context) {
	monthStr := c.DefaultQuery("month", "1")
	yearStr := c.DefaultQuery("year", "2024")
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	summary, err := h.salesUsecase.GetSummaryKPI(month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success retrieving summary KPI",
		"data":    summary,
	})
}

func (h *SalesHandler) CreateTransaction(c *gin.Context) {
	var req usecase.CreateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		fmt.Printf("DEBUG: CreateTransaction binding error: %v\n", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Auto-fill EmployeeID from token if empty
	if req.EmployeeID.String() == "00000000-0000-0000-0000-000000000000" {
		if userIDStr, exists := c.Get("userID"); exists {
			userID := userIDStr.(uuid.UUID)
			employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
			if err == nil && employee != nil {
				req.EmployeeID = employee.ID
				if employee.CompanyID != nil {
					req.CompanyID = *employee.CompanyID
				}
			}
		}
	}

	trx, err := h.salesUsecase.CreateTransaction(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Transaction created successfully",
		"data":    trx,
	})
}

func (h *SalesHandler) GetPendingTransactions(c *gin.Context) {
	var employeeID uuid.UUID
	employeeIDStr := c.Query("employee_id")

	if employeeIDStr != "" {
		parsed, err := uuid.Parse(employeeIDStr)
		if err == nil {
			employeeID = parsed
		}
	} else {
		// Resolve from token
		if userIDStr, exists := c.Get("userID"); exists {
			userID := userIDStr.(uuid.UUID)
			employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
			if err == nil && employee != nil {
				employeeID = employee.ID
			}
		}
	}

	if employeeID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "employee_id is required or token must be associated with an employee"})
		return
	}

	pending, err := h.salesUsecase.GetPendingTransactions(employeeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success",
		"data":    pending,
	})
}

func (h *SalesHandler) GetHistoryTransactions(c *gin.Context) {
	var employeeID uuid.UUID
	employeeIDStr := c.Query("employee_id")

	if employeeIDStr != "" {
		parsed, err := uuid.Parse(employeeIDStr)
		if err == nil {
			employeeID = parsed
		}
	} else {
		// Resolve from token
		if userIDStr, exists := c.Get("userID"); exists {
			userID := userIDStr.(uuid.UUID)
			employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
			if err == nil && employee != nil {
				employeeID = employee.ID
			}
		}
	}

	if employeeID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "employee_id is required or token must be associated with an employee"})
		return
	}

	history, err := h.salesUsecase.GetHistoryTransactions(employeeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success",
		"data":    history,
	})
}

func (h *SalesHandler) VerifyTransaction(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid transaction id"})
		return
	}

	var req usecase.VerifyTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.salesUsecase.VerifyTransaction(id, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Transaction verified successfully",
	})
}


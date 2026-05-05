package http

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

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
		sales.GET("/transactions/all-pending", h.GetAllPending)
		sales.GET("/transactions/all", h.GetAllTransactions)
		sales.PUT("/transactions/:id", h.UpdateTransaction)
		sales.DELETE("/transactions/:id", h.DeleteTransaction)
		sales.POST("/targets", h.SetKPITarget)
		sales.GET("/reports/excel", h.ExportExcel)
		sales.GET("/reports/summary", h.GetSummary)
		sales.GET("/reports/performance", h.GetPerformance)
		sales.POST("/upload", h.UploadPhoto)
	}
}

func (h *SalesHandler) SetupMobileRoutes(router *gin.RouterGroup) {
	sales := router.Group("/sales")
	{
		sales.POST("/transactions", h.CreateTransaction)
		sales.GET("/transactions/pending", h.GetPendingTransactions)
		sales.GET("/transactions/history", h.GetHistoryTransactions)
		sales.PATCH("/transactions/:id/verify", h.VerifyTransaction)
		sales.GET("/visit-plans", h.GetVisitPlan)
		sales.GET("/transactions/receipt/:receipt_no", h.GetByReceipt)
		sales.POST("/transactions/:id/payments", h.RecordPayment)
		sales.GET("/stores/:id/outstanding", h.GetOutstandingByStore)
		sales.GET("/transactions/due-date", h.GetByDueDate)
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

func (h *SalesHandler) GetPerformance(c *gin.Context) {
	monthStr := c.DefaultQuery("month", "1")
	yearStr := c.DefaultQuery("year", "2024")
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	performance, err := h.salesUsecase.GetPerformanceList(month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success retrieving performance list",
		"data":    performance,
	})
}

func (h *SalesHandler) GetAllPending(c *gin.Context) {
	pending, err := h.salesUsecase.GetAllPendingTransactions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success retrieving all pending transactions",
		"data":    pending,
	})
}

func (h *SalesHandler) GetAllTransactions(c *gin.Context) {
	trxs, err := h.salesUsecase.GetAllTransactions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success",
		"data":    trxs,
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

func (h *SalesHandler) UpdateTransaction(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid transaction id"})
		return
	}

	var req usecase.ManualEntryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.salesUsecase.UpdateTransaction(id, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Transaction updated successfully"})
}

func (h *SalesHandler) DeleteTransaction(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid transaction id"})
		return
	}

	err = h.salesUsecase.DeleteTransaction(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Transaction deleted successfully"})
}

func (h *SalesHandler) SetKPITarget(c *gin.Context) {
	var req struct {
		EmployeeID      uuid.UUID `json:"employee_id" binding:"required"`
		Month           int       `json:"month" binding:"required"`
		Year            int       `json:"year" binding:"required"`
		TargetOmzet     float64   `json:"target_omzet"`
		TargetNewStores int       `json:"target_new_stores"`
		WorkingTerritory string   `json:"working_territory"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.salesUsecase.SetKPITarget(req.EmployeeID, req.Month, req.Year, req.TargetOmzet, req.TargetNewStores, req.WorkingTerritory)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "KPI target set successfully"})
}

func (h *SalesHandler) UploadPhoto(c *gin.Context) {
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file is received"})
		return
	}

	// Create uploads directory if not exists
	uploadDir := "./uploads/sales"
	// For simplicity, we assume the directory exists or is created by the system
	
	filename := fmt.Sprintf("%s_%s", uuid.New().String(), file.Filename)
	filePath := fmt.Sprintf("%s/%s", uploadDir, filename)

	if err := c.SaveUploadedFile(file, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to save the file"})
		return
	}

	fileURL := fmt.Sprintf("/api/v1/uploads/sales/%s", filename)
	c.JSON(http.StatusOK, gin.H{
		"message": "File uploaded successfully",
		"url":     fileURL,
	})
}

func (h *SalesHandler) GetVisitPlan(c *gin.Context) {
	var employeeID uuid.UUID
	if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && employee != nil {
			employeeID = employee.ID
		}
	}

	if employeeID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Unauthorized employee"})
		return
	}

	dateStr := c.Query("date")
	date := time.Now()
	if dateStr != "" {
		if parsed, err := time.Parse("2006-01-02", dateStr); err == nil {
			date = parsed
		}
	}

	plan, err := h.salesUsecase.GetVisitPlan(employeeID, date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success",
		"data":    plan,
	})
}

func (h *SalesHandler) GetByReceipt(c *gin.Context) {
	receiptNo := c.Param("receipt_no")
	if receiptNo == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "receipt_no is required"})
		return
	}

	trx, err := h.salesUsecase.GetTransactionByReceipt(receiptNo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if trx == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Transaction not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success",
		"data":    trx,
	})
}

func (h *SalesHandler) RecordPayment(c *gin.Context) {
	trxID := uuid.MustParse(c.Param("id"))
	
	var req usecase.RecordPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.TransactionID = trxID

	// Resolve EmployeeID from token if empty
	if req.EmployeeID == uuid.Nil {
		if userIDStr, exists := c.Get("userID"); exists {
			userID := userIDStr.(uuid.UUID)
			employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
			if err == nil && employee != nil {
				req.EmployeeID = employee.ID
			}
		}
	}

	if err := h.salesUsecase.RecordPayment(req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Pembayaran berhasil dicatat"})
}

func (h *SalesHandler) GetOutstandingByStore(c *gin.Context) {
	storeID := uuid.MustParse(c.Param("id"))
	
	trxs, err := h.salesUsecase.GetOutstandingTransactionsByStore(storeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success",
		"data":    trxs,
	})
}

func (h *SalesHandler) GetByDueDate(c *gin.Context) {
	dateStr := c.Query("date")
	date := time.Now()
	if dateStr != "" {
		if parsed, err := time.Parse("2006-01-02", dateStr); err == nil {
			date = parsed
		}
	}

	var employeeID uuid.UUID
	if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && employee != nil {
			employeeID = employee.ID
		}
	}

	trxs, err := h.salesUsecase.GetTransactionsByDueDate(date, employeeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success",
		"data":    trxs,
	})
}

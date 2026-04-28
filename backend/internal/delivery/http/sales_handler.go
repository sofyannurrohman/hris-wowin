package http

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type SalesHandler struct {
	salesUsecase usecase.SalesUsecase
}

func NewSalesHandler(salesUsecase usecase.SalesUsecase) *SalesHandler {
	return &SalesHandler{
		salesUsecase: salesUsecase,
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


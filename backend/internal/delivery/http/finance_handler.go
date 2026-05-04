package http

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type FinanceHandler struct {
	usecase usecase.FinanceUsecase
}

func NewFinanceHandler(u usecase.FinanceUsecase) *FinanceHandler {
	return &FinanceHandler{u}
}

func (h *FinanceHandler) RegisterRoutes(r *gin.RouterGroup) {
	finance := r.Group("/finance")
	{
		finance.GET("/profit-loss", h.GetProfitLoss)
	}
}

func (h *FinanceHandler) GetProfitLoss(c *gin.Context) {
	companyIDStr := c.Query("company_id")
	if companyIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "company_id is required"})
		return
	}

	companyID, err := uuid.Parse(companyIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid company_id"})
		return
	}

	month, _ := strconv.Atoi(c.Query("month"))
	year, _ := strconv.Atoi(c.Query("year"))

	if month == 0 || year == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "month and year are required"})
		return
	}

	report, err := h.usecase.GetProfitLossReport(companyID, month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Success",
		"data":    report,
	})
}

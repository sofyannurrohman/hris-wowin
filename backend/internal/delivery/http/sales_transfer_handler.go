package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/internal/utils"
)

type SalesTransferHandler struct {
	usecase usecase.SalesTransferUsecase
}

func NewSalesTransferHandler(u usecase.SalesTransferUsecase) *SalesTransferHandler {
	return &SalesTransferHandler{u}
}

func (h *SalesTransferHandler) CreateTransfer(c *gin.Gin) {
	branchID, err := uuid.Parse(c.Param("branchId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid branch id"})
		return
	}

	var req usecase.CreateSalesTransferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.usecase.CreateTransfer(branchID, req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "transfer created successfully"})
}

func (h *SalesTransferHandler) CompleteTransfer(c *gin.Gin) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	if err := h.usecase.CompleteTransfer(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "transfer completed successfully"})
}

func (h *SalesTransferHandler) CancelTransfer(c *gin.Gin) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	if err := h.usecase.CancelTransfer(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "transfer cancelled successfully"})
}

func (h *SalesTransferHandler) GetTransfers(c *gin.Gin) {
	branchID, err := uuid.Parse(c.Param("branchId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid branch id"})
		return
	}

	transfers, err := h.usecase.GetTransfersByBranch(branchID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": transfers})
}

func (h *SalesTransferHandler) GetSalesStock(c *gin.Gin) {
	employeeID, err := uuid.Parse(c.Param("employeeId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid employee id"})
		return
	}

	stocks, err := h.usecase.GetSalesStock(employeeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": stocks})
}

func (h *SalesTransferHandler) DeleteTransfer(c *gin.Gin) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	if err := h.usecase.DeleteTransfer(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "transfer deleted successfully"})
}

func (h *SalesTransferHandler) RegisterRoutes(r *gin.RouterGroup) {
	transfers := r.Group("/sales-transfers")
	{
		transfers.POST("/branch/:branchId", h.CreateTransfer)
		transfers.GET("/branch/:branchId", h.GetTransfers)
		transfers.PATCH("/:id/complete", h.CompleteTransfer)
		transfers.PATCH("/:id/cancel", h.CancelTransfer)
		transfers.DELETE("/:id", h.DeleteTransfer)
		transfers.GET("/stock/:employeeId", h.GetSalesStock)
	}
}

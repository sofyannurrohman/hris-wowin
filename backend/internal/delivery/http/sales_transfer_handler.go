package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

type SalesTransferHandler struct {
	usecase usecase.SalesTransferUsecase
}

func NewSalesTransferHandler(u usecase.SalesTransferUsecase) *SalesTransferHandler {
	return &SalesTransferHandler{u}
}

func (h *SalesTransferHandler) CreateTransfer(c *gin.Context) {
	branchID, err := uuid.Parse(c.Param("branchId"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "invalid branch id")
		return
	}

	var req usecase.CreateSalesTransferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.usecase.CreateTransfer(branchID, req); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "transfer created successfully", nil)
}

func (h *SalesTransferHandler) CompleteTransfer(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "invalid id")
		return
	}

	if err := h.usecase.CompleteTransfer(id); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "transfer completed successfully", nil)
}

func (h *SalesTransferHandler) CancelTransfer(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "invalid id")
		return
	}

	if err := h.usecase.CancelTransfer(id); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "transfer cancelled successfully", nil)
}

func (h *SalesTransferHandler) GetTransfers(c *gin.Context) {
	branchID, err := uuid.Parse(c.Param("branchId"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "invalid branch id")
		return
	}

	transfers, err := h.usecase.GetTransfersByBranch(branchID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "transfers fetched successfully", transfers)
}

func (h *SalesTransferHandler) GetSalesStock(c *gin.Context) {
	employeeID, err := uuid.Parse(c.Param("employeeId"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "invalid employee id")
		return
	}

	stocks, err := h.usecase.GetSalesStock(employeeID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "stocks fetched successfully", stocks)
}

func (h *SalesTransferHandler) DeleteTransfer(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "invalid id")
		return
	}

	if err := h.usecase.DeleteTransfer(id); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "transfer deleted successfully", nil)
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

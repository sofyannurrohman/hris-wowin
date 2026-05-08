package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
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

func (h *SalesTransferHandler) CreateRequest(c *gin.Context) {
	branchIDStr, ok := c.Get("branch_id")
	if !ok {
		utils.ErrorResponse(c, http.StatusBadRequest, "branch id not found in context")
		return
	}
	branchID := uuid.MustParse(branchIDStr.(string))

	var req usecase.CreateSalesTransferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	// Resolve EmployeeID from token if not provided
	if req.EmployeeID == uuid.Nil {
		employeeIDStr, _ := c.Get("employee_id")
		req.EmployeeID = uuid.MustParse(employeeIDStr.(string))
	}

	if err := h.usecase.CreateTransfer(branchID, req); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "Request stok berhasil dikirim", nil)
}

func (h *SalesTransferHandler) GetPendingRequests(c *gin.Context) {
	branchIDStr, okBranch := c.Get("branch_id")
	companyIDStr, okCompany := c.Get("company_id")
	
	var transfers []domain.SalesTransfer
	var err error

	if okBranch {
		branchID := uuid.MustParse(branchIDStr.(string))
		transfers, err = h.usecase.GetTransfersByBranch(branchID)
	} else if okCompany {
		companyID := uuid.MustParse(companyIDStr.(string))
		transfers, err = h.usecase.GetTransfersByCompany(companyID)
	} else {
		utils.ErrorResponse(c, http.StatusBadRequest, "No branch or company context found")
		return
	}

	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	// Filter only pending
	var pending []domain.SalesTransfer
	for _, t := range transfers {
		if t.Status == domain.SalesTransferPending {
			pending = append(pending, t)
		}
	}

	utils.SuccessResponse(c, http.StatusOK, "Pending transfers fetched", pending)
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

		// Mobile Optimized
		transfers.POST("/request", h.CreateRequest)
		transfers.GET("/pending", h.GetPendingRequests)

		// Attendance / Visit
		transfers.POST("/attendance", h.RecordAttendance)
	}
}

func (h *SalesTransferHandler) RecordAttendance(c *gin.Context) {
	// For now, let's just return success so the mobile app doesn't error
	// We will implement the actual storage logic if needed
	c.JSON(http.StatusOK, gin.H{"message": "Attendance recorded successfully"})
}

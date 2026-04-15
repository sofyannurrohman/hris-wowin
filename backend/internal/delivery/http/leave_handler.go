package http

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

type LeaveHandler struct {
	leaveUseCase usecase.LeaveUseCase
}

func NewLeaveHandler(leaveUseCase usecase.LeaveUseCase) *LeaveHandler {
	return &LeaveHandler{leaveUseCase}
}

func (h *LeaveHandler) SetupRoutes(router *gin.RouterGroup) {
	leaves := router.Group("/time-off")
	{
		leaves.POST("/request", h.SubmitLeave)
		leaves.GET("/balances", h.GetMyBalances)
		leaves.GET("/history", h.GetMyLeaves)

		// Admin/Manager only
		admin := leaves.Group("")
		admin.Use(RoleMiddleware(string(domain.RoleSuperAdmin), string(domain.RoleHRAdmin)))
		{
			admin.GET("", h.GetAllLeaves)
			admin.PUT("/:id/approve", h.ApproveLeave)
		}
	}

	// Admin-only leave balances endpoint
	leaveBalances := router.Group("/leave-balances")
	leaveBalances.Use(RoleMiddleware(string(domain.RoleSuperAdmin), string(domain.RoleHRAdmin)))
	{
		leaveBalances.GET("", h.GetAllLeaveBalances)
	}
}

func (h *LeaveHandler) SubmitLeave(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	var req usecase.SubmitLeaveRequest
	// Try to bind from form first (for multipart)
	if err := c.ShouldBind(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	// Handle file upload
	file, err := c.FormFile("attachment")
	if err == nil {
		// Save file
		filename := uuid.New().String() + "-" + file.Filename
		savePath := "uploads/attachments/" + filename
		if err := c.SaveUploadedFile(file, savePath); err != nil {
			utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to save attachment")
			return
		}
		req.AttachmentURL = "/uploads/attachments/" + filename
	}

	err = h.leaveUseCase.SubmitLeave(userID, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "Leave request submitted successfully", nil)
}

func (h *LeaveHandler) GetMyLeaves(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "10")

	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)

	leaves, err := h.leaveUseCase.GetMyLeaves(userID, page, limit)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get leaves")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Leaves fetched", leaves)
}

func (h *LeaveHandler) GetMyBalances(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	balances, err := h.leaveUseCase.GetMyBalances(userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get leave balances")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Leave balances fetched", balances)
}

func (h *LeaveHandler) GetAllLeaves(c *gin.Context) {
	status := c.Query("status")
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "10")

	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)

	leaves, err := h.leaveUseCase.GetAllLeaves(status, page, limit)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get leaves")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Leaves fetched", leaves)
}

func (h *LeaveHandler) ApproveLeave(c *gin.Context) {
	approverIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	approverID := approverIDStr.(uuid.UUID)

	leaveIDStr := c.Param("id")
	leaveID, err := uuid.Parse(leaveIDStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid leave ID format")
		return
	}

	var req usecase.ApproveLeaveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	err = h.leaveUseCase.ApproveReturnLeave(leaveID, approverID, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	message := "Leave status updated successfully"
	if req.Status == "REJECTED" {
		message = "Leave successfully rejected and balance refunded"
	}

	utils.SuccessResponse(c, http.StatusOK, message, nil)
}

func (h *LeaveHandler) GetAllLeaveBalances(c *gin.Context) {
	balances, err := h.leaveUseCase.GetAllLeaveBalances()
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get all leave balances")
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "Leave balances fetched", balances)
}

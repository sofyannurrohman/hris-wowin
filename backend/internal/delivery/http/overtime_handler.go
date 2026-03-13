package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

type OvertimeHandler struct {
	overtimeUseCase usecase.OvertimeUseCase
}

func NewOvertimeHandler(overtimeUseCase usecase.OvertimeUseCase) *OvertimeHandler {
	return &OvertimeHandler{overtimeUseCase: overtimeUseCase}
}

func (h *OvertimeHandler) SetupRoutes(router *gin.RouterGroup) {
	overtimeGroup := router.Group("/overtimes")
	{
		overtimeGroup.POST("/", h.RequestOvertime)
		overtimeGroup.GET("/me", h.GetMyOvertimes)
		// For admin/manager
		overtimeGroup.GET("/", h.GetAllOvertimes)
		overtimeGroup.PUT("/:id/status", h.UpdateStatus)
		overtimeGroup.PUT("/:id", h.UpdateOvertime)
		overtimeGroup.DELETE("/:id", h.DeleteOvertime)
	}
}

func (h *OvertimeHandler) RequestOvertime(c *gin.Context) {
	val, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}

	userID, ok := val.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Invalid user ID type in context")
		return
	}


	var req usecase.OvertimeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	ot, err := h.overtimeUseCase.RequestOvertime(userID, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}


	utils.SuccessResponse(c, http.StatusCreated, "Overtime requested successfully", ot)
}

func (h *OvertimeHandler) GetMyOvertimes(c *gin.Context) {
	val, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := val.(uuid.UUID)


	ots, err := h.overtimeUseCase.GetUserOvertimes(userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Overtime history retrieved", ots)
}

func (h *OvertimeHandler) GetAllOvertimes(c *gin.Context) {
	ots, err := h.overtimeUseCase.GetAllOvertimes()
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "All overtime requests retrieved", ots)
}

func (h *OvertimeHandler) UpdateStatus(c *gin.Context) {
	// Extract the Approver's User ID from JWT context
	val, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}

	approverUserID, ok := val.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Invalid user ID type in context")
		return
	}


	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid ID format")
		return
	}

	var req struct {
		Status       string  `json:"status" binding:"required"`
		RejectReason *string `json:"reject_reason"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.overtimeUseCase.UpdateOvertimeStatus(id, approverUserID, req.Status, req.RejectReason); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	msg := "Status updated successfully"
	if req.Status == "rejected" {
		msg = "Overtime request rejected"
	}

	utils.SuccessResponse(c, http.StatusOK, msg, nil)
}
func (h *OvertimeHandler) UpdateOvertime(c *gin.Context) {
	val, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := val.(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid ID format")
		return
	}

	var req usecase.OvertimeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.overtimeUseCase.UpdateOvertime(userID, id, req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Overtime updated successfully", nil)
}

func (h *OvertimeHandler) DeleteOvertime(c *gin.Context) {
	val, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := val.(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid ID format")
		return
	}

	if err := h.overtimeUseCase.DeleteOvertime(userID, id); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Overtime deleted successfully", nil)
}

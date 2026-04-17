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

type ReimbursementHandler struct {
	useCase usecase.ReimbursementUseCase
}

func NewReimbursementHandler(useCase usecase.ReimbursementUseCase) *ReimbursementHandler {
	return &ReimbursementHandler{useCase}
}

func (h *ReimbursementHandler) SetupRoutes(router *gin.RouterGroup) {
	reimbursements := router.Group("/reimbursements")
	{
		reimbursements.POST("", h.Submit)
		reimbursements.GET("/my", h.GetHistory)
		reimbursements.PUT("/:id", h.Update)
		reimbursements.DELETE("/:id", h.Delete)

		// Admin only
		admin := reimbursements.Group("")
		admin.Use(RoleMiddleware(string(domain.RoleSuperAdmin), string(domain.RoleHRAdmin)))
		{
			admin.GET("", h.GetAll)
			admin.PUT("/:id/approve", h.Approve)
		}
	}
}

func (h *ReimbursementHandler) Submit(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	var req usecase.SubmitReimbursementRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	// Handle file upload
	file, err := c.FormFile("attachment")
	if err == nil {
		filename := uuid.New().String() + "-" + file.Filename
		savePath := "uploads/attachments/" + filename
		if err := c.SaveUploadedFile(file, savePath); err != nil {
			utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to save attachment")
			return
		}
		req.AttachmentURL = "/uploads/attachments/" + filename
	}

	err = h.useCase.Submit(userID, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "Reimbursement submitted successfully", nil)
}

func (h *ReimbursementHandler) GetHistory(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	reimbursements, err := h.useCase.GetHistory(userID, page, limit)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Reimbursements fetched", reimbursements)
}

func (h *ReimbursementHandler) GetAll(c *gin.Context) {
	status := c.Query("status")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	reimbursements, err := h.useCase.GetAll(status, page, limit)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "All reimbursements fetched", reimbursements)
}

func (h *ReimbursementHandler) Approve(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid id format")
		return
	}

	var req usecase.ApproveReimbursementRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	err = h.useCase.Approve(userID, id, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Reimbursement status updated", nil)
}

func (h *ReimbursementHandler) Update(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid id format")
		return
	}

	var req usecase.SubmitReimbursementRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	// Handle file upload if any
	file, err := c.FormFile("attachment")
	if err == nil {
		filename := uuid.New().String() + "-" + file.Filename
		savePath := "uploads/attachments/" + filename
		if err := c.SaveUploadedFile(file, savePath); err != nil {
			utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to save attachment")
			return
		}
		req.AttachmentURL = "/uploads/attachments/" + filename
	}

	err = h.useCase.UpdateMyReimbursement(userID, id, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Reimbursement updated successfully", nil)
}

func (h *ReimbursementHandler) Delete(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid id format")
		return
	}

	err = h.useCase.DeleteMyReimbursement(userID, id)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Reimbursement deleted successfully", nil)
}

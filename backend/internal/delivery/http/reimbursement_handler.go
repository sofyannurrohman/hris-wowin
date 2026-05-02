package http

import (
	"net/http"
	"os"
	"path/filepath"
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
		manage := reimbursements.Group("/manage")
		manage.Use(RoleMiddleware(string(domain.RoleSuperAdmin), string(domain.RoleHRAdmin)))
		{
			manage.GET("", h.GetAll)
			manage.POST("", h.AdminCreate)
			manage.PUT("/:id", h.AdminUpdate)
			manage.DELETE("/:id", h.AdminDelete)
			manage.PUT("/:id/approve", h.Approve)
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
	attachmentURL, err := h.handleFileUpload(c)
	if err != nil {
		if err == http.ErrHandlerTimeout {
			utils.ErrorResponse(c, http.StatusRequestEntityTooLarge, "File size too large (max 20MB)")
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to save attachment")
		return
	}
	if attachmentURL != "" {
		req.AttachmentURL = attachmentURL
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
	attachmentURL, err := h.handleFileUpload(c)
	if err != nil && err != http.ErrMissingFile {
		if err == http.ErrHandlerTimeout {
			utils.ErrorResponse(c, http.StatusRequestEntityTooLarge, "File size too large (max 20MB)")
			return
		}
		// Log error but continue if it's just a missing file (already handled by handleFileUpload returning empty string)
	}
	if attachmentURL != "" {
		req.AttachmentURL = attachmentURL
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

func (h *ReimbursementHandler) AdminCreate(c *gin.Context) {
	var req usecase.AdminReimbursementRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	// Handle file upload
	attachmentURL, err := h.handleFileUpload(c)
	if err != nil {
		if err == http.ErrHandlerTimeout {
			utils.ErrorResponse(c, http.StatusRequestEntityTooLarge, "File size too large (max 20MB)")
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to save attachment")
		return
	}
	if attachmentURL != "" {
		req.AttachmentURL = attachmentURL
	}

	err = h.useCase.AdminCreate(req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "Reimbursement created successfully", nil)
}

func (h *ReimbursementHandler) AdminUpdate(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid id format")
		return
	}

	var req usecase.AdminReimbursementRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	// Handle file upload
	attachmentURL, err := h.handleFileUpload(c)
	if err != nil {
		if err == http.ErrHandlerTimeout {
			utils.ErrorResponse(c, http.StatusRequestEntityTooLarge, "File size too large (max 20MB)")
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to save attachment")
		return
	}
	if attachmentURL != "" {
		req.AttachmentURL = attachmentURL
	}

	err = h.useCase.AdminUpdate(id, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Reimbursement updated successfully", nil)
}

func (h *ReimbursementHandler) AdminDelete(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid id format")
		return
	}

	err = h.useCase.AdminDelete(id)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Reimbursement deleted successfully", nil)
}

func (h *ReimbursementHandler) handleFileUpload(c *gin.Context) (string, error) {
	file, err := c.FormFile("attachment")
	if err != nil {
		if err == http.ErrMissingFile {
			return "", nil
		}
		return "", err
	}

	// Check file size (20MB limit)
	if file.Size > 20*1024*1024 {
		return "", http.ErrHandlerTimeout // Still using a placeholder that's easily recognizable
	}

	filename := uuid.New().String() + "-" + filepath.Base(file.Filename)
	uploadDir := "uploads/attachments"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		return "", err
	}
	savePath := uploadDir + "/" + filename
	if err := c.SaveUploadedFile(file, savePath); err != nil {
		return "", err
	}

	return "/uploads/attachments/" + filename, nil
}

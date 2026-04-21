package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

type AnnouncementHandler struct {
	usecase usecase.AnnouncementUseCase
}

func NewAnnouncementHandler(usecase usecase.AnnouncementUseCase) *AnnouncementHandler {
	return &AnnouncementHandler{usecase: usecase}
}

func (h *AnnouncementHandler) SetupRoutes(router *gin.RouterGroup) {
	router.GET("/announcements", h.GetAnnouncements)
	router.GET("/admin/announcements", h.AdminListAnnouncements)
	router.POST("/announcements", h.CreateAnnouncement)
	router.PUT("/announcements/:id", h.UpdateAnnouncement)
	router.DELETE("/announcements/:id", h.DeleteAnnouncement)
}

func (h *AnnouncementHandler) GetAnnouncements(c *gin.Context) {
	announcements, err := h.usecase.GetAnnouncements()
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Announcements fetched successfully", announcements)
}

func (h *AnnouncementHandler) AdminListAnnouncements(c *gin.Context) {
	announcements, err := h.usecase.AdminListAnnouncements()
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Admin announcements fetched successfully", announcements)
}

func (h *AnnouncementHandler) CreateAnnouncement(c *gin.Context) {
	var req usecase.CreateAnnouncementRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.usecase.CreateAnnouncement(req); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "Announcement created successfully", nil)
}

func (h *AnnouncementHandler) UpdateAnnouncement(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid ID format")
		return
	}

	var req usecase.UpdateAnnouncementRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.usecase.UpdateAnnouncement(id, req); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Announcement updated successfully", nil)
}

func (h *AnnouncementHandler) DeleteAnnouncement(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid ID format")
		return
	}

	if err := h.usecase.DeleteAnnouncement(id); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Announcement deleted successfully", nil)
}

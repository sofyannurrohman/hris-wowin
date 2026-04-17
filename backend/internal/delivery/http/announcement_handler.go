package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
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
}

func (h *AnnouncementHandler) GetAnnouncements(c *gin.Context) {
	announcements, err := h.usecase.GetAnnouncements()
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Announcements fetched successfully", announcements)
}

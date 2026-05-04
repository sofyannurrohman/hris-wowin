package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type NotificationHandler struct {
	repo repository.NotificationRepository
}

func NewNotificationHandler(repo repository.NotificationRepository) *NotificationHandler {
	return &NotificationHandler{repo}
}

func (h *NotificationHandler) RegisterRoutes(r *gin.RouterGroup) {
	notifications := r.Group("/notifications")
	{
		notifications.GET("", h.GetNotifications)
		notifications.POST("/:id/read", h.MarkAsRead)
	}
}

func (h *NotificationHandler) GetNotifications(c *gin.Context) {
	companyIDStr, _ := c.Get("company_id")
	branchIDStr, _ := c.Get("branch_id")
	
	companyID := uuid.MustParse(companyIDStr.(string))
	branchID := uuid.Nil
	if branchIDStr != nil && branchIDStr != "" {
		branchID = uuid.MustParse(branchIDStr.(string))
	}

	notifications, err := h.repo.GetByBranch(companyID, branchID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, notifications)
}

func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	if err := h.repo.MarkAsRead(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Notification marked as read"})
}

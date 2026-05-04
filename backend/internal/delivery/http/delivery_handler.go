package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type DeliveryHandler struct {
	usecase usecase.DeliveryUsecase
}

func NewDeliveryHandler(u usecase.DeliveryUsecase) *DeliveryHandler {
	return &DeliveryHandler{u}
}

func (h *DeliveryHandler) RegisterRoutes(r *gin.RouterGroup) {
	delivery := r.Group("/delivery")
	{
		delivery.POST("/batch", h.CreateBatch)
		delivery.GET("/tasks", h.GetTasks)
		delivery.GET("/batch/:do_no", h.GetDetail)
		delivery.POST("/batch/:do_no/start", h.StartDelivery)
		delivery.POST("/items/:id/confirm", h.ConfirmItem)
	}
}

func (h *DeliveryHandler) CreateBatch(c *gin.Context) {
	var req usecase.CreateBatchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	batch, err := h.usecase.CreateBatch(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, batch)
}

func (h *DeliveryHandler) GetTasks(c *gin.Context) {
	driverIDStr, _ := c.Get("employee_id")
	if driverIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "driver identity not found"})
		return
	}

	driverID := uuid.MustParse(driverIDStr.(string))
	tasks, err := h.usecase.GetDriverTasks(driverID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, tasks)
}

func (h *DeliveryHandler) GetDetail(c *gin.Context) {
	doNo := c.Param("do_no")
	batch, err := h.usecase.GetBatchDetail(doNo)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Surat jalan tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, batch)
}

func (h *DeliveryHandler) StartDelivery(c *gin.Context) {
	doNo := c.Param("do_no")
	if err := h.usecase.StartDelivery(doNo); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Delivery started successfully"})
}

func (h *DeliveryHandler) ConfirmItem(c *gin.Context) {
	itemID := uuid.MustParse(c.Param("id"))
	var req struct {
		Status domain.DeliveryItemStatus `json:"status" binding:"required"`
		Notes  string                    `json:"notes"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.usecase.ConfirmItemDelivery(itemID, req.Status, req.Notes); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Item status updated"})
}

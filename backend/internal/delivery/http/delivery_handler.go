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
		delivery.POST("/batch/:id/approve", h.ApproveBatch)
		delivery.POST("/batch/:id/assign", h.AssignArmada)
		delivery.GET("/tasks", h.GetTasks)
		delivery.GET("/batch/:id", h.GetDetail)
		delivery.POST("/batch/:id/start", h.StartDelivery)
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

func (h *DeliveryHandler) ApproveBatch(c *gin.Context) {
	batchID := uuid.MustParse(c.Param("id"))
	
	// Assuming employee_id is set by AuthMiddleware
	adminIDStr, _ := c.Get("employee_id")
	if adminIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "admin identity not found"})
		return
	}
	adminID := uuid.MustParse(adminIDStr.(string))

	if err := h.usecase.ApproveBatch(batchID, adminID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Surat jalan berhasil disetujui"})
}

func (h *DeliveryHandler) AssignArmada(c *gin.Context) {
	batchID := uuid.MustParse(c.Param("id"))
	
	var req struct {
		DriverID  uuid.UUID `json:"driver_id" binding:"required"`
		VehicleID uuid.UUID `json:"vehicle_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	supervisorIDStr, _ := c.Get("employee_id")
	if supervisorIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "supervisor identity not found"})
		return
	}
	supervisorID := uuid.MustParse(supervisorIDStr.(string))

	if err := h.usecase.AssignArmada(batchID, req.DriverID, req.VehicleID, supervisorID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Armada berhasil ditugaskan"})
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
	doNo := c.Param("id")
	batch, err := h.usecase.GetBatchDetail(doNo)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Surat jalan tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, batch)
}

func (h *DeliveryHandler) StartDelivery(c *gin.Context) {
	doNo := c.Param("id")
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

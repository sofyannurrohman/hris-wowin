package http

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

type DeliveryHandler struct {
	usecase         usecase.DeliveryUsecase
	employeeUseCase usecase.EmployeeUsecase
}

func NewDeliveryHandler(u usecase.DeliveryUsecase, e usecase.EmployeeUsecase) *DeliveryHandler {
	return &DeliveryHandler{u, e}
}

func (h *DeliveryHandler) RegisterRoutes(r *gin.RouterGroup) {
	delivery := r.Group("/delivery")
	{
		delivery.POST("/batch", h.CreateBatch)
		delivery.POST("/batch/:id/supervisor-approve", h.SupervisorApprove)
		delivery.POST("/batch/:id/approve", h.ApproveBatch)
		delivery.POST("/batch/:id/assign", h.AssignArmada)
		delivery.GET("/batches", h.ListBatches)
		delivery.PUT("/batches/:id", h.UpdateBatch)
		delivery.DELETE("/batches/:id", h.DeleteBatch)
		delivery.GET("/tasks", h.GetTasks)
		delivery.GET("/history", h.GetHistory)
		delivery.GET("/batch/:id", h.GetDetail)
		delivery.POST("/batch/:id/start", h.StartDelivery)
		delivery.POST("/batch/:id/cash", h.UpdateCash)
		delivery.POST("/items/:id/confirm", h.ConfirmItem)
		delivery.POST("/items/confirm-by-receipt", h.ConfirmByReceipt)
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
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Batch created successfully", batch)
}

func (h *DeliveryHandler) ApproveBatch(c *gin.Context) {
	batchID := uuid.MustParse(c.Param("id"))
	
	// Resolve employee_id from userID
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user identity not found"})
		return
	}
	userID := userIDStr.(uuid.UUID)
	employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
	if err != nil || employee == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "employee identity not found"})
		return
	}
	adminID := employee.ID

	if err := h.usecase.ApproveBatch(batchID, adminID); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Surat jalan berhasil disetujui", nil)
}

func (h *DeliveryHandler) SupervisorApprove(c *gin.Context) {
	batchID := uuid.MustParse(c.Param("id"))
	
	// Resolve employee_id from userID
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user identity not found"})
		return
	}
	userID := userIDStr.(uuid.UUID)
	employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
	if err != nil || employee == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "supervisor identity not found"})
		return
	}
	supervisorID := employee.ID

	if err := h.usecase.SupervisorApproveBatch(batchID, supervisorID); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Batch berhasil disetujui Supervisor", nil)
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

	// Resolve employee_id from userID
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user identity not found"})
		return
	}
	userID := userIDStr.(uuid.UUID)
	employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
	if err != nil || employee == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "supervisor identity not found"})
		return
	}
	supervisorID := employee.ID

	if err := h.usecase.AssignArmada(batchID, req.DriverID, req.VehicleID, supervisorID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Armada berhasil ditugaskan"})
}

func (h *DeliveryHandler) ListBatches(c *gin.Context) {
	batches, err := h.usecase.ListBatches()
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Batches fetched successfully", batches)
}

func (h *DeliveryHandler) UpdateBatch(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	var req usecase.CreateBatchRequest // Reuse request struct
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.usecase.UpdateBatchItems(id, req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Batch updated successfully"})
}

func (h *DeliveryHandler) DeleteBatch(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid batch id"})
		return
	}

	err = h.usecase.DeleteBatch(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Batch deleted successfully"})
}

func (h *DeliveryHandler) GetTasks(c *gin.Context) {
	// Resolve employee_id from userID
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "driver identity not found"})
		return
	}
	userID := userIDStr.(uuid.UUID)
	employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
	if err != nil || employee == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "driver identity not found"})
		return
	}
	driverID := employee.ID

	tasks, err := h.usecase.GetDriverTasks(driverID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, tasks)
}

func (h *DeliveryHandler) GetHistory(c *gin.Context) {
	// Resolve employee_id from userID
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "driver identity not found"})
		return
	}
	userID := userIDStr.(uuid.UUID)
	employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
	if err != nil || employee == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "driver identity not found"})
		return
	}
	driverID := employee.ID

	history, err := h.usecase.GetDriverHistory(driverID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, history)
}

func (h *DeliveryHandler) GetDetail(c *gin.Context) {
	idOrNo := c.Param("id")
	fmt.Printf("DEBUG: GetDetail request for [%s]\n", idOrNo)
	
	var batch *domain.DeliveryBatch
	var err error

	// Try parsing as UUID first
	if id, parseErr := uuid.Parse(idOrNo); parseErr == nil {
		batch, err = h.usecase.GetBatchByID(id)
	} else {
		batch, err = h.usecase.GetBatchDetail(idOrNo)
	}

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Batch atau Surat jalan tidak ditemukan"})
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
func (h *DeliveryHandler) ConfirmByReceipt(c *gin.Context) {
	var req struct {
		ReceiptNo string `json:"receipt_no" binding:"required"`
		Notes     string `json:"notes"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.usecase.ConfirmItemByReceipt(req.ReceiptNo, req.Notes); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Item marked as DELIVERED"})
}

func (h *DeliveryHandler) UpdateCash(c *gin.Context) {
	batchID := uuid.MustParse(c.Param("id"))
	var req struct {
		Amount float64 `json:"amount" binding:"required"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.usecase.UpdateBatchCash(batchID, req.Amount); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Cash amount updated"})
}

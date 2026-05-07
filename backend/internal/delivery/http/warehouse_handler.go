package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type WarehouseHandler struct {
	usecase usecase.WarehouseUsecase
}

func NewWarehouseHandler(u usecase.WarehouseUsecase) *WarehouseHandler {
	return &WarehouseHandler{u}
}

func (h *WarehouseHandler) RegisterRoutes(r *gin.RouterGroup) {
	warehouse := r.Group("/warehouse")
	{
		warehouse.GET("/stock", h.GetInventory)
		warehouse.GET("/logs", h.GetLogs)
		warehouse.GET("/transfers/pending", h.GetPendingShipments)
		warehouse.POST("/transfers/:id/receive", h.ReceiveShipment)
		warehouse.GET("/transfers/do/:do_no", h.GetByDO)
		warehouse.POST("/transfers/do/:do_no/receive", h.ReceiveByDO)
		warehouse.POST("/transfers/:id/approve", h.ApproveShipment)
		warehouse.POST("/transfers/:id/reject", h.RejectShipment)
		warehouse.POST("/adjust", h.AdjustStock)
		warehouse.POST("/stock-limit", h.SetStockLimit)
		warehouse.POST("/dispatch/invoice/:receipt_no", h.DispatchByInvoice)
	}
}

func (h *WarehouseHandler) GetInventory(c *gin.Context) {
	branchID := uuid.Nil
	if val, ok := c.Get("branch_id"); ok && val != "" {
		branchID = uuid.MustParse(val.(string))
	} else if bid := c.Query("branch_id"); bid != "" {
		branchID = uuid.MustParse(bid)
	}

	if branchID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "branch_id not found in session or query"})
		return
	}
	
	inventory, err := h.usecase.GetInventory(branchID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, inventory)
}

func (h *WarehouseHandler) GetLogs(c *gin.Context) {
	branchID := uuid.Nil
	if val, ok := c.Get("branch_id"); ok && val != "" {
		branchID = uuid.MustParse(val.(string))
	} else if bid := c.Query("branch_id"); bid != "" {
		branchID = uuid.MustParse(bid)
	}

	if branchID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "branch_id not found in session or query"})
		return
	}

	logs, err := h.usecase.GetWarehouseLogs(branchID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, logs)
}

func (h *WarehouseHandler) GetPendingShipments(c *gin.Context) {
	branchID := uuid.Nil
	if val, ok := c.Get("branch_id"); ok && val != "" {
		branchID = uuid.MustParse(val.(string))
	} else if bid := c.Query("branch_id"); bid != "" {
		branchID = uuid.MustParse(bid)
	}

	if branchID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "branch_id not found in session or query"})
		return
	}

	transfers, err := h.usecase.GetPendingShipments(branchID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, transfers)
}

func (h *WarehouseHandler) ReceiveShipment(c *gin.Context) {
	transferID := uuid.MustParse(c.Param("id"))
	if err := h.usecase.ReceiveShipment(transferID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Shipment received and stock updated"})
}

func (h *WarehouseHandler) ApproveShipment(c *gin.Context) {
	transferID := uuid.MustParse(c.Param("id"))
	if err := h.usecase.ApproveTransfer(transferID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Shipment approved by branch"})
}

func (h *WarehouseHandler) RejectShipment(c *gin.Context) {
	transferID := uuid.MustParse(c.Param("id"))
	if err := h.usecase.RejectTransfer(transferID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Shipment rejected by branch"})
}

func (h *WarehouseHandler) SetStockLimit(c *gin.Context) {
	var req struct {
		ProductID uuid.UUID `json:"product_id" binding:"required"`
		Limit     int       `json:"limit" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	branchID := uuid.Nil
	if val, ok := c.Get("branch_id"); ok && val != "" {
		branchID = uuid.MustParse(val.(string))
	} else if bid := c.Query("branch_id"); bid != "" {
		branchID = uuid.MustParse(bid)
	}

	if branchID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "branch_id not found in session or query"})
		return
	}

	if err := h.usecase.SetStockLimit(branchID, req.ProductID, req.Limit); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Stock limit updated successfully"})
}

func (h *WarehouseHandler) AdjustStock(c *gin.Context) {
	var req struct {
		ProductID uuid.UUID `json:"product_id" binding:"required"`
		Quantity  int       `json:"quantity" binding:"required"`
		Reason    string    `json:"reason"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	branchID := uuid.Nil
	if val, ok := c.Get("branch_id"); ok && val != "" {
		branchID = uuid.MustParse(val.(string))
	} else if bid := c.Query("branch_id"); bid != "" {
		branchID = uuid.MustParse(bid)
	}

	if branchID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "branch_id not found in session or query"})
		return
	}

	if err := h.usecase.AdjustStock(branchID, req.ProductID, req.Quantity, req.Reason); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Stock adjusted successfully"})
}

func (h *WarehouseHandler) GetByDO(c *gin.Context) {
	doNo := c.Param("do_no")
	transfer, err := h.usecase.GetTransferByDO(doNo)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Surat jalan tidak ditemukan"})
		return
	}
	c.JSON(http.StatusOK, transfer)
}

func (h *WarehouseHandler) ReceiveByDO(c *gin.Context) {
	doNo := c.Param("do_no")
	if err := h.usecase.ReceiveShipmentByDO(doNo); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Barang telah diterima dan stok gudang diperbarui"})
}

func (h *WarehouseHandler) DispatchByInvoice(c *gin.Context) {
	receiptNo := c.Param("receipt_no")
	
	branchID := uuid.Nil
	if val, ok := c.Get("branch_id"); ok && val != "" {
		branchID = uuid.MustParse(val.(string))
	} else if bid := c.Query("branch_id"); bid != "" {
		branchID = uuid.MustParse(bid)
	}

	if branchID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "branch_id not found in session or query"})
		return
	}

	if err := h.usecase.DispatchByInvoice(receiptNo, branchID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Barang telah dikeluarkan dari gudang dan status nota diperbarui"})
}

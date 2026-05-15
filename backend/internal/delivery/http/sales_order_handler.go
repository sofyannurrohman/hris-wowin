package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type SalesOrderHandler struct {
	soUsecase       usecase.SalesOrderUsecase
	employeeUseCase usecase.EmployeeUsecase
}

func NewSalesOrderHandler(soUsecase usecase.SalesOrderUsecase, employeeUseCase usecase.EmployeeUsecase) *SalesOrderHandler {
	return &SalesOrderHandler{soUsecase, employeeUseCase}
}

// RegisterRoutes mendaftarkan semua route SO untuk admin (web dashboard).
func (h *SalesOrderHandler) RegisterRoutes(router *gin.RouterGroup) {
	so := router.Group("/admin/sales-orders")
	{
		so.GET("", h.GetByBranch)
		so.GET("/:id", h.GetByID)
		so.POST("/manual", h.CreateSOManual)

		// *** ALUR BARU: Admin Nota ***
		so.PATCH("/:id/admin-confirm", h.AdminConfirmSO)
		so.PATCH("/:id/admin-reject", h.AdminRejectSO)

		// Driver routes (dipanggil dari mobile)
		so.PATCH("/:id/confirm-delivery", h.ConfirmDelivery)
		so.PATCH("/:id/collect-payment", h.CollectPayment)

		// Legacy routes
		so.PATCH("/:id/confirm", h.ConfirmSO)
		so.PATCH("/:id/reject", h.RejectSO)
		so.PATCH("/:id/cancel", h.CancelSO)
		so.PATCH("/:id/process-warehouse", h.ProcessByWarehouse)
		so.PATCH("/:id/override-backorder", h.OverrideBackorder)
		so.PATCH("/:id/confirm-pod", h.ConfirmPOD)
		so.POST("/:id/convert", h.ConvertToInvoice)
		so.DELETE("/:id", h.DeleteSO)
	}
}



// SetupMobileRoutes mendaftarkan route SO untuk salesman (mobile app).
func (h *SalesOrderHandler) SetupMobileRoutes(router *gin.RouterGroup) {
	so := router.Group("/sales-orders") // This matches mobile AppConstants.baseUrl + 'sales-orders/'
	{
		so.POST("/confirm-delivery", h.ConfirmDelivery)
		so.POST("/collect-payment", h.CollectPayment)
	}

	orders := router.Group("/sales/orders")
	{
		orders.POST("", h.CreateSO)
		orders.GET("", h.GetByEmployee)
		orders.DELETE("/:id", h.CancelSO)
	}
}

// --- Admin & Mobile Handlers ---

func (h *SalesOrderHandler) GetByBranch(c *gin.Context) {
	branchIDStr := c.Query("branch_id")
	status := c.DefaultQuery("status", "ALL")

	branchID, err := uuid.Parse(branchIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "branch_id tidak valid"})
		return
	}

	orders, err := h.soUsecase.GetSOByBranch(branchID, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Success", "data": orders})
}

func (h *SalesOrderHandler) GetByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}
	so, err := h.soUsecase.GetSOByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "SO tidak ditemukan"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Success", "data": so})
}

// CreateSO digunakan oleh salesman (mobile) untuk membuat SO baru.
func (h *SalesOrderHandler) CreateSO(c *gin.Context) {
	var req usecase.CreateSORequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Resolve EmployeeID dari token jika tidak disertakan
	if req.EmployeeID == uuid.Nil {
		if userIDStr, exists := c.Get("userID"); exists {
			userID := userIDStr.(uuid.UUID)
			emp, err := h.employeeUseCase.GetEmployeeByUserID(userID)
			if err == nil && emp != nil {
				req.EmployeeID = emp.ID
				if emp.CompanyID != nil {
					req.CompanyID = *emp.CompanyID
				}
			}
		}
	}

	so, err := h.soUsecase.CreateSO(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "Pesanan berhasil dibuat", "data": so})
}

// CreateSOManual digunakan oleh admin (web) untuk membuat SO secara manual.
func (h *SalesOrderHandler) CreateSOManual(c *gin.Context) {
	var req usecase.CreateSORequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	so, err := h.soUsecase.CreateSO(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "Pesanan berhasil dibuat", "data": so})
}

func (h *SalesOrderHandler) GetByEmployee(c *gin.Context) {
	var employeeID uuid.UUID
	empIDStr := c.Query("employee_id")

	if empIDStr != "" {
		employeeID, _ = uuid.Parse(empIDStr)
	} else if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		emp, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && emp != nil {
			employeeID = emp.ID
		}
	}

	if employeeID == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "employee_id diperlukan"})
		return
	}

	orders, err := h.soUsecase.GetSOByEmployee(employeeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Success", "data": orders})
}

// ConfirmSO mengkonfirmasi SO dan me-reserve stok di gudang.
func (h *SalesOrderHandler) ConfirmSO(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	var confirmedByID uuid.UUID
	if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		emp, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && emp != nil {
			confirmedByID = emp.ID
		}
	}

	if err := h.soUsecase.ConfirmSO(id, confirmedByID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Pesanan dikonfirmasi dan stok berhasil di-reserve"})
}

// RejectSO menolak SO.
func (h *SalesOrderHandler) RejectSO(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	var req struct {
		Notes string `json:"notes"`
	}
	c.ShouldBindJSON(&req)

	var rejectedByID uuid.UUID
	if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		emp, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && emp != nil {
			rejectedByID = emp.ID
		}
	}

	if err := h.soUsecase.RejectSO(id, rejectedByID, req.Notes); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Pesanan ditolak"})
}

// CancelSO membatalkan SO dan melepas reserve stok jika sudah dikonfirmasi.
func (h *SalesOrderHandler) CancelSO(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	if err := h.soUsecase.CancelSO(id); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Pesanan dibatalkan dan reserve stok dilepas"})
}

// ConvertToInvoice mengkonversi SO ke Faktur Penjualan (SalesTransaction).
// Ini memotong stok secara permanen.
func (h *SalesOrderHandler) ConvertToInvoice(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	var req struct {
		CompanyID uuid.UUID `json:"company_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	invoice, err := h.soUsecase.ConvertToInvoice(id, req.CompanyID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{
		"message": "Faktur Penjualan berhasil diterbitkan dan stok sudah dipotong",
		"data":    invoice,
	})
}

// ProcessByWarehouse digunakan oleh tim gudang untuk validasi fisik barang.
func (h *SalesOrderHandler) ProcessByWarehouse(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	var req usecase.ProcessByWarehouseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.SOID = id

	// Resolve ProcessedByID dari token
	if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		emp, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && emp != nil {
			req.ProcessedByID = emp.ID
		}
	}

	if err := h.soUsecase.ProcessByWarehouse(req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Barang berhasil diproses gudang dan Surat Jalan telah diterbitkan"})
}

// ConfirmPOD konfirmasi penerimaan barang (Proof of Delivery).
func (h *SalesOrderHandler) ConfirmPOD(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	var req usecase.ConfirmPODRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.SOID = id

	if err := h.soUsecase.ConfirmPOD(req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Penerimaan barang berhasil dikonfirmasi (POD)"})
}

// DeleteSO menghapus SO (hanya yang berstatus DRAFT).
func (h *SalesOrderHandler) DeleteSO(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	if err := h.soUsecase.DeleteSO(id); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Pesanan berhasil dihapus"})
}
func (h *SalesOrderHandler) OverrideBackorder(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	if err := h.soUsecase.OverrideBackorder(id); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Pesanan berhasil di-override ke antrean kirim"})
}

// =============================================================================
// ALUR BARU: Admin Nota
// =============================================================================

func (h *SalesOrderHandler) AdminConfirmSO(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	// Resolve admin employee ID dari token
	adminID, err := h.resolveEmployeeID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Identitas admin tidak ditemukan"})
		return
	}

	if err := h.soUsecase.AdminConfirmSO(id, adminID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Nota berhasil diverifikasi oleh Admin Nota"})
}

func (h *SalesOrderHandler) AdminRejectSO(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	adminID, err := h.resolveEmployeeID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Identitas admin tidak ditemukan"})
		return
	}

	var req struct {
		Notes string `json:"notes"`
	}
	_ = c.ShouldBindJSON(&req)

	if err := h.soUsecase.AdminRejectSO(id, adminID, req.Notes); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Nota berhasil ditolak"})
}

// =============================================================================
// ALUR BARU: Driver — Konfirmasi Pengiriman & Tagih Pembayaran
// =============================================================================

func (h *SalesOrderHandler) ConfirmDelivery(c *gin.Context) {
	var req usecase.ConfirmDeliveryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// If ID is in param (PATCH /admin/sales-orders/:id/confirm-delivery), override body so_id
	idStr := c.Param("id")
	if idStr != "" {
		id, err := uuid.Parse(idStr)
		if err == nil {
			req.SOID = id
		}
	}

	if err := h.soUsecase.ConfirmDelivery(req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Pengiriman berhasil dikonfirmasi"})
}

func (h *SalesOrderHandler) CollectPayment(c *gin.Context) {
	var req usecase.CollectPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// If ID is in param (PATCH /admin/sales-orders/:id/collect-payment), override body so_id
	idStr := c.Param("id")
	if idStr != "" {
		id, err := uuid.Parse(idStr)
		if err == nil {
			req.SOID = id
		}
	}

	data, err := h.soUsecase.CollectPayment(req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Pembayaran berhasil dicatat",
		"data":    data,
	})
}

// resolveEmployeeID adalah helper untuk mendapatkan employee ID dari JWT token.
func (h *SalesOrderHandler) resolveEmployeeID(c *gin.Context) (uuid.UUID, error) {
	userIDRaw, exists := c.Get("userID")
	if !exists {
		return uuid.Nil, gin.Error{}
	}
	userID := userIDRaw.(uuid.UUID)
	employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
	if err != nil || employee == nil {
		return uuid.Nil, err
	}
	return employee.ID, nil
}

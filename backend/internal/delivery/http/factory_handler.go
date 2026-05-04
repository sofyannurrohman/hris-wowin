package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type FactoryHandler struct {
	usecase usecase.FactoryUsecase
}

func NewFactoryHandler(u usecase.FactoryUsecase) *FactoryHandler {
	return &FactoryHandler{u}
}

func (h *FactoryHandler) RegisterRoutes(r *gin.RouterGroup) {
	factory := r.Group("/factory")
	{
		factory.GET("", h.GetAllFactories)
		factory.POST("", h.CreateFactory)
		factory.GET("/:id", h.GetFactoryDetail)
		factory.PUT("/:id", h.UpdateFactory)
		factory.DELETE("/:id", h.DeleteFactory)

		factory.GET("/products", h.GetProducts)
		factory.POST("/products", h.CreateProduct)

		factory.GET("/:id/inventory", h.GetInventory)
		factory.GET("/:id/inventory/logs", h.GetInventoryLogs)
		factory.POST("/:id/production", h.LogProduction)
		factory.GET("/:id/production", h.GetProductionHistory)

		factory.POST("/:id/transfer/request", h.RequestShipment)
		factory.POST("/transfer/:id/ship", h.ExecuteShipment)
		factory.GET("/:id/transfer", h.GetTransferHistory)
	}
}

func (h *FactoryHandler) GetAllFactories(c *gin.Context) {
	companyIDStr, _ := c.Get("company_id")
	companyID := uuid.MustParse(companyIDStr.(string))
	factories, err := h.usecase.GetAllFactories(companyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, factories)
}

func (h *FactoryHandler) CreateFactory(c *gin.Context) {
	var factory domain.Factory
	if err := c.ShouldBindJSON(&factory); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	companyIDStr, _ := c.Get("company_id")
	factory.CompanyID = uuid.MustParse(companyIDStr.(string))
	if err := h.usecase.CreateFactory(&factory); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, factory)
}

func (h *FactoryHandler) GetFactoryDetail(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	factory, err := h.usecase.GetFactoryDetail(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Factory not found"})
		return
	}
	c.JSON(http.StatusOK, factory)
}

func (h *FactoryHandler) UpdateFactory(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	var factory domain.Factory
	if err := c.ShouldBindJSON(&factory); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	factory.ID = id
	if err := h.usecase.UpdateFactory(&factory); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, factory)
}

func (h *FactoryHandler) DeleteFactory(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	if err := h.usecase.DeleteFactory(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Factory deleted"})
}

func (h *FactoryHandler) CreateProduct(c *gin.Context) {
	var product domain.Product
	if err := c.ShouldBindJSON(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	companyIDStr, _ := c.Get("company_id")
	product.CompanyID = uuid.MustParse(companyIDStr.(string))
	if err := h.usecase.CreateProduct(&product); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, product)
}

func (h *FactoryHandler) GetProducts(c *gin.Context) {
	companyIDStr, _ := c.Get("company_id")
	companyID := uuid.MustParse(companyIDStr.(string))
	products, err := h.usecase.GetProducts(companyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, products)
}

func (h *FactoryHandler) GetInventory(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	inventory, err := h.usecase.GetFactoryInventory(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, inventory)
}

func (h *FactoryHandler) GetInventoryLogs(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	logs, err := h.usecase.GetInventoryLogs(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, logs)
}

func (h *FactoryHandler) LogProduction(c *gin.Context) {
	factoryID := uuid.MustParse(c.Param("id"))
	var req struct {
		ProductID  uuid.UUID `json:"product_id" binding:"required"`
		EmployeeID uuid.UUID `json:"employee_id" binding:"required"`
		Quantity   int       `json:"quantity" binding:"required"`
		Notes      string    `json:"notes"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.usecase.LogProduction(factoryID, req.ProductID, req.EmployeeID, req.Quantity, req.Notes); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Production logged successfully"})
}

func (h *FactoryHandler) GetProductionHistory(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	history, err := h.usecase.GetProductionHistory(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, history)
}

func (h *FactoryHandler) RequestShipment(c *gin.Context) {
	factoryID := uuid.MustParse(c.Param("id"))
	var req struct {
		ToBranchID uuid.UUID `json:"to_branch_id" binding:"required"`
		ProductID  uuid.UUID `json:"product_id" binding:"required"`
		Quantity   int       `json:"quantity" binding:"required"`
		Notes      string    `json:"notes"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.usecase.RequestShipment(factoryID, req.ToBranchID, req.ProductID, req.Quantity, req.Notes); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Shipment request created"})
}

func (h *FactoryHandler) ExecuteShipment(c *gin.Context) {
	transferID := uuid.MustParse(c.Param("id"))
	if err := h.usecase.ExecuteApprovedShipment(transferID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Shipment executed and factory stock reduced"})
}

func (h *FactoryHandler) GetTransferHistory(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	history, err := h.usecase.GetTransferHistory(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, history)
}

package http

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"

	"strings"
	"time"

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
		factory.GET("/stock/inventory", h.GetAllInventory)
		factory.GET("/stock/transfers", h.GetAllTransfers)
		factory.GET("/stock/production", h.GetAllProductionHistory)
		factory.GET("/demand", h.GetBackorderDemand)
		factory.GET("/dashboard/stats", h.GetDashboardStats)
		factory.POST("/products", h.CreateProduct)
		factory.PUT("/products/:id", h.UpdateProduct)
		factory.DELETE("/products/:id", h.DeleteProduct)

		factory.GET("/:id/inventory", h.GetInventory)
		factory.GET("/:id/inventory/logs", h.GetInventoryLogs)
		factory.POST("/:id/production", h.LogProduction)
		factory.GET("/:id/production", h.GetProductionHistory)
		factory.PUT("/production/:id", h.UpdateProductionLog)
		factory.DELETE("/production/:id", h.DeleteProductionLog)

		factory.POST("/:id/inventory/adjust", h.AdjustStock)
		factory.POST("/:id/transfer/request", h.RequestShipment)
		factory.POST("/transfer/:id/ship", h.ExecuteShipment)
		factory.PUT("/transfer/:id/approve", h.ApproveTransfer)
		factory.PUT("/transfer/:id", h.UpdateTransfer)
		factory.DELETE("/transfer/:id", h.DeleteTransfer)
		factory.GET("/:id/transfer", h.GetTransferHistory)

		factory.GET("/recipes", h.GetRecipes)
		factory.GET("/recipes/:product_id", h.GetRecipeByProduct)
		factory.POST("/recipes", h.CreateRecipe)
		factory.DELETE("/recipes/:id", h.DeleteRecipe)
	}
}


func (h *FactoryHandler) GetAllFactories(c *gin.Context) {
	val, _ := c.Get("companyID")
	companyID := val.(uuid.UUID)
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
	val, _ := c.Get("companyID")
	factory.CompanyID = val.(uuid.UUID)
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
	if err := c.ShouldBind(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Handle Image Upload
	imageURL, err := h.handleImageUpload(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image: " + err.Error()})
		return
	}
	if imageURL != "" {
		product.ImageURL = imageURL
	}

	val, _ := c.Get("companyID")
	product.CompanyID = val.(uuid.UUID)
	if err := h.usecase.CreateProduct(&product); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, product)
}

func (h *FactoryHandler) UpdateProduct(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	var product domain.Product
	if err := c.ShouldBind(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Handle Image Upload
	imageURL, err := h.handleImageUpload(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image: " + err.Error()})
		return
	}
	if imageURL != "" {
		product.ImageURL = imageURL
	}

	product.ID = id
	if err := h.usecase.UpdateProduct(&product); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, product)
}

func (h *FactoryHandler) DeleteProduct(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	if err := h.usecase.DeleteProduct(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Product deleted"})
}

func (h *FactoryHandler) GetProducts(c *gin.Context) {
	companyID := uuid.Nil
	if val, ok := c.Get("companyID"); ok {
		companyID = val.(uuid.UUID)
	}

	// Allow override via query param for specific company lookup
	if qID := c.Query("company_id"); qID != "" {
		if id, err := uuid.Parse(qID); err == nil {
			companyID = id
		}
	}

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

func (h *FactoryHandler) GetAllInventory(c *gin.Context) {
	val, _ := c.Get("companyID")
	companyID := val.(uuid.UUID)
	inventory, err := h.usecase.GetAllInventory(companyID)
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
		ProductID       uuid.UUID  `json:"product_id" binding:"required"`
		EmployeeID      uuid.UUID  `json:"employee_id" binding:"required"`
		Quantity        int        `json:"quantity" binding:"required"`
		CartonCount     int        `json:"carton_count"`
		PiecesPerCarton int        `json:"pieces_per_carton"`
		Notes           string     `json:"notes"`
		BatchNo         string     `json:"batch_no"`
		ExpiryDate      *time.Time `json:"expiry_date"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.usecase.LogProduction(factoryID, req.ProductID, req.EmployeeID, req.Quantity, req.CartonCount, req.PiecesPerCarton, req.Notes, req.BatchNo, req.ExpiryDate); err != nil {
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

func (h *FactoryHandler) GetAllProductionHistory(c *gin.Context) {
	val, _ := c.Get("companyID")
	companyID := val.(uuid.UUID)
	history, err := h.usecase.GetAllProductionHistory(companyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, history)
}

func (h *FactoryHandler) RequestShipment(c *gin.Context) {
	factoryID := uuid.MustParse(c.Param("id"))
	var req struct {
		ToBranchID         uuid.UUID                    `json:"to_branch_id" binding:"required"`
		Items              []domain.ProductTransferItem `json:"items" binding:"required"`
		Notes              string                       `json:"notes"`
		EstimatedArrival   *time.Time                   `json:"estimated_arrival"`
		TargetShipmentDate *time.Time                   `json:"target_shipment_date"`
		InitiatedBy        string                       `json:"initiated_by"`
		VehicleID          *uuid.UUID                   `json:"vehicle_id"`
		DriverID           *uuid.UUID                   `json:"driver_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	initiatedBy := req.InitiatedBy
	if initiatedBy == "" {
		initiatedBy = "FACTORY"
	}

	if err := h.usecase.RequestShipment(factoryID, req.ToBranchID, req.Items, req.Notes, req.TargetShipmentDate, req.EstimatedArrival, initiatedBy, req.VehicleID, req.DriverID); err != nil {
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

func (h *FactoryHandler) ApproveTransfer(c *gin.Context) {
	transferID := uuid.MustParse(c.Param("id"))
	if err := h.usecase.ApproveTransfer(transferID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Transfer approved"})
}

func (h *FactoryHandler) UpdateProductionLog(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	var req struct {
		Quantity        int    `json:"quantity" binding:"required"`
		CartonCount     int    `json:"carton_count"`
		PiecesPerCarton int    `json:"pieces_per_carton"`
		Notes           string `json:"notes"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.usecase.UpdateProductionLog(id, req.Quantity, req.CartonCount, req.PiecesPerCarton, req.Notes); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Production log updated successfully"})
}

func (h *FactoryHandler) DeleteProductionLog(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	if err := h.usecase.DeleteProductionLog(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Production log deleted and stock reversed"})
}

func (h *FactoryHandler) AdjustStock(c *gin.Context) {
	factoryID := uuid.MustParse(c.Param("id"))
	var req struct {
		ProductID uuid.UUID `json:"product_id" binding:"required"`
		Quantity  int       `json:"quantity" binding:"required"`
		Reason    string    `json:"reason"`
		BatchNo   string    `json:"batch_no"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.usecase.AdjustStock(factoryID, req.ProductID, req.Quantity, req.Reason, req.BatchNo); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Stock adjusted successfully"})
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

func (h *FactoryHandler) UpdateTransfer(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	var data map[string]interface{}
	if err := c.ShouldBindJSON(&data); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.usecase.UpdateTransfer(id, data); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Transfer updated"})
}

func (h *FactoryHandler) DeleteTransfer(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	if err := h.usecase.DeleteTransfer(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Transfer deleted"})
}

func (h *FactoryHandler) GetAllTransfers(c *gin.Context) {
	val, _ := c.Get("companyID")
	companyID := val.(uuid.UUID)
	history, err := h.usecase.GetAllTransfers(companyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, history)
}

func (h *FactoryHandler) handleImageUpload(c *gin.Context) (string, error) {
	contentType := c.GetHeader("Content-Type")
	if !strings.HasPrefix(contentType, "multipart/form-data") {
		return "", nil
	}

	file, err := c.FormFile("image")
	if err != nil {
		if err == http.ErrMissingFile {
			return "", nil
		}
		return "", err
	}

	// Limit 5MB
	if file.Size > 5*1024*1024 {
		return "", fmt.Errorf("file size exceeds 5MB limit")
	}

	filename := uuid.New().String() + filepath.Ext(file.Filename)
	uploadDir := "uploads/products"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		return "", err
	}

	savePath := filepath.Join(uploadDir, filename)
	if err := c.SaveUploadedFile(file, savePath); err != nil {
		return "", err
	}

	return "/uploads/products/" + filename, nil
}

func (h *FactoryHandler) GetRecipes(c *gin.Context) {
	val, _ := c.Get("companyID")
	companyID := val.(uuid.UUID)
	recipes, err := h.usecase.GetRecipes(companyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, recipes)
}

func (h *FactoryHandler) GetRecipeByProduct(c *gin.Context) {
	productID := uuid.MustParse(c.Param("product_id"))
	recipe, err := h.usecase.GetRecipeByProduct(productID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if recipe == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recipe not found"})
		return
	}
	c.JSON(http.StatusOK, recipe)
}

func (h *FactoryHandler) CreateRecipe(c *gin.Context) {
	var recipe domain.ProductionRecipe
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.usecase.CreateRecipe(&recipe); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, recipe)
}

func (h *FactoryHandler) DeleteRecipe(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	if err := h.usecase.DeleteRecipe(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Recipe deleted"})
}

func (h *FactoryHandler) GetBackorderDemand(c *gin.Context) {
	companyID, _ := uuid.Parse(c.Query("company_id"))
	demand, err := h.usecase.GetBackorderDemand(companyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": demand})
}

func (h *FactoryHandler) GetDashboardStats(c *gin.Context) {
	val, _ := c.Get("companyID")
	companyID := val.(uuid.UUID)
	
	stats, err := h.usecase.GetDashboardStats(companyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

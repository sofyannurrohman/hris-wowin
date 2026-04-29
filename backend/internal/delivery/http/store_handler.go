package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type StoreHandler struct {
	storeRepo       repository.StoreRepository
	employeeUseCase usecase.EmployeeUsecase
}

func NewStoreHandler(storeRepo repository.StoreRepository, employeeUseCase usecase.EmployeeUsecase) *StoreHandler {
	return &StoreHandler{
		storeRepo:       storeRepo,
		employeeUseCase: employeeUseCase,
	}
}

func (h *StoreHandler) SetupRoutes(r *gin.RouterGroup) {
	stores := r.Group("/stores")
	{
		stores.GET("", h.GetAll)
		stores.GET("/:id", h.GetByID)
		stores.POST("", h.Create)
		stores.PUT("/:id", h.Update)
		stores.DELETE("/:id", h.Delete)
	}
}

// GET /api/v1/stores?assigned_employee_id=<uuid>&company_id=<uuid>
func (h *StoreHandler) GetAll(c *gin.Context) {
	stores, err := h.storeRepo.FindAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Optional filter: assigned_employee_id or from token
	assignedEmpIDStr := c.Query("assigned_employee_id")
	var assignedEmpID uuid.UUID
	var errParse error

	if assignedEmpIDStr != "" {
		assignedEmpID, errParse = uuid.Parse(assignedEmpIDStr)
	} else {
		// Resolve from token if available
		if userIDStr, exists := c.Get("userID"); exists {
			userID := userIDStr.(uuid.UUID)
			employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
			if err == nil && employee != nil {
				assignedEmpID = employee.ID
				errParse = nil
			} else {
				errParse = err
			}
		}
	}

	if errParse == nil && assignedEmpID != uuid.Nil {
		filtered := make([]domain.Store, 0)
		for _, s := range stores {
			if s.AssignedEmployeeID != nil && *s.AssignedEmployeeID == assignedEmpID {
				filtered = append(filtered, s)
			}
		}
		stores = filtered
	}

	c.JSON(http.StatusOK, gin.H{"data": stores, "total": len(stores)})
}

// GET /api/v1/stores/:id
func (h *StoreHandler) GetByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid store ID"})
		return
	}

	store, err := h.storeRepo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if store == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Store not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": store})
}

// POST /api/v1/stores
func (h *StoreHandler) Create(c *gin.Context) {
	var store domain.Store
	if err := c.ShouldBindJSON(&store); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Auto assign to current employee if logged in
	if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && employee != nil {
			if store.CompanyID == uuid.Nil && employee.CompanyID != nil {
				store.CompanyID = *employee.CompanyID
			}
			if store.AssignedEmployeeID == nil || *store.AssignedEmployeeID == uuid.Nil {
				store.AssignedEmployeeID = &employee.ID
			}
		}
	}

	if err := h.storeRepo.Create(&store); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Store created successfully", "data": store})
}

// PUT /api/v1/stores/:id
func (h *StoreHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid store ID"})
		return
	}

	existing, err := h.storeRepo.FindByID(id)
	if err != nil || existing == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Store not found"})
		return
	}

	if err := c.ShouldBindJSON(existing); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	existing.ID = id // ensure ID not overwritten

	if err := h.storeRepo.Update(existing); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Store updated successfully", "data": existing})
}

// DELETE /api/v1/stores/:id
func (h *StoreHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid store ID"})
		return
	}

	if err := h.storeRepo.Delete(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Store deleted successfully"})
}

package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type BannerOrderHandler struct {
	bannerOrderUseCase usecase.BannerOrderUseCase
	employeeUseCase    usecase.EmployeeUsecase
}

func NewBannerOrderHandler(bannerOrderUseCase usecase.BannerOrderUseCase, employeeUseCase usecase.EmployeeUsecase) *BannerOrderHandler {
	return &BannerOrderHandler{
		bannerOrderUseCase: bannerOrderUseCase,
		employeeUseCase:    employeeUseCase,
	}
}

func (h *BannerOrderHandler) SetupRoutes(r *gin.RouterGroup) {
	bannerOrders := r.Group("/banner-orders")
	{
		bannerOrders.POST("", h.CreateOrder)
	}
}

func (h *BannerOrderHandler) CreateOrder(c *gin.Context) {
	var req domain.BannerOrder
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Auto assign company_id and employee_id from token
	if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		employee, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && employee != nil {
			if employee.CompanyID != nil {
				req.CompanyID = *employee.CompanyID
			}
			req.EmployeeID = employee.ID
		}
	}

	if req.EmployeeID == uuid.Nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized or employee not found"})
		return
	}

	if err := h.bannerOrderUseCase.CreateOrder(&req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Banner order created successfully",
		"data":    req,
	})
}

package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type VehicleHandler struct {
	usecase usecase.VehicleUsecase
}

func NewVehicleHandler(u usecase.VehicleUsecase) *VehicleHandler {
	return &VehicleHandler{u}
}

func (h *VehicleHandler) RegisterRoutes(r *gin.RouterGroup) {
	vehicles := r.Group("/vehicles")
	{
		vehicles.GET("", h.GetAllVehicles)
		vehicles.POST("", h.CreateVehicle)
		vehicles.GET("/:id", h.GetVehicleDetail)
		vehicles.PUT("/:id", h.UpdateVehicle)
		vehicles.DELETE("/:id", h.DeleteVehicle)
	}
}

func (h *VehicleHandler) GetAllVehicles(c *gin.Context) {
	companyIDStr, _ := c.Get("company_id")
	companyID := uuid.MustParse(companyIDStr.(string))
	
	vehicles, err := h.usecase.GetVehicles(companyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, vehicles)
}

func (h *VehicleHandler) CreateVehicle(c *gin.Context) {
	var vehicle domain.Vehicle
	if err := c.ShouldBindJSON(&vehicle); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	companyIDStr, _ := c.Get("company_id")
	vehicle.CompanyID = uuid.MustParse(companyIDStr.(string))

	if err := h.usecase.CreateVehicle(&vehicle); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, vehicle)
}

func (h *VehicleHandler) GetVehicleDetail(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	vehicle, err := h.usecase.GetVehicleDetail(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vehicle not found"})
		return
	}
	c.JSON(http.StatusOK, vehicle)
}

func (h *VehicleHandler) UpdateVehicle(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	var vehicle domain.Vehicle
	if err := c.ShouldBindJSON(&vehicle); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	vehicle.ID = id

	if err := h.usecase.UpdateVehicle(&vehicle); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, vehicle)
}

func (h *VehicleHandler) DeleteVehicle(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	if err := h.usecase.DeleteVehicle(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Vehicle deleted"})
}

package http

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
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
		vehicles.GET("/:id/logs", h.GetVehicleLogs)
	}
}

func (h *VehicleHandler) GetAllVehicles(c *gin.Context) {
	val, _ := c.Get("companyID")
	companyID := val.(uuid.UUID)
	
	vehicles, err := h.usecase.GetVehicles(companyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, vehicles)
}

func (h *VehicleHandler) CreateVehicle(c *gin.Context) {
	var vehicle domain.Vehicle
	var err error
	if strings.Contains(c.GetHeader("Content-Type"), "multipart/form-data") {
		err = c.ShouldBindWith(&vehicle, binding.FormMultipart)
	} else {
		err = c.ShouldBindJSON(&vehicle)
	}

	if err != nil {
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
		vehicle.ImageURL = imageURL
	}

	val, _ := c.Get("companyID")
	vehicle.CompanyID = val.(uuid.UUID)

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
	var err error
	if strings.Contains(c.GetHeader("Content-Type"), "multipart/form-data") {
		err = c.ShouldBindWith(&vehicle, binding.FormMultipart)
	} else {
		err = c.ShouldBindJSON(&vehicle)
	}

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	vehicle.ID = id

	// Handle Image Upload
	imageURL, err := h.handleImageUpload(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image: " + err.Error()})
		return
	}
	if imageURL != "" {
		vehicle.ImageURL = imageURL
	}

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

func (h *VehicleHandler) GetVehicleLogs(c *gin.Context) {
	id := uuid.MustParse(c.Param("id"))
	logs, err := h.usecase.GetVehicleLogs(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, logs)
}

func (h *VehicleHandler) handleImageUpload(c *gin.Context) (string, error) {
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
	uploadDir := "uploads/vehicles"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		return "", err
	}

	savePath := filepath.Join(uploadDir, filename)
	if err := c.SaveUploadedFile(file, savePath); err != nil {
		return "", err
	}

	return "/uploads/vehicles/" + filename, nil
}

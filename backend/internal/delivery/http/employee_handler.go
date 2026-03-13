package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

type EmployeeHandler struct {
	employeeUsecase usecase.EmployeeUsecase
}

func NewEmployeeHandler(employeeUsecase usecase.EmployeeUsecase) *EmployeeHandler {
	return &EmployeeHandler{
		employeeUsecase: employeeUsecase,
	}
}

func (h *EmployeeHandler) SetupRoutes(router *gin.RouterGroup) {
	// Group under /employees
	employees := router.Group("/employees")

	// Authenticated but common endpoints
	employees.GET("/profile", h.GetProfile)
	employees.PUT("/profile", h.UpdateProfile)

	// Open Admin Endpoints
	admin := employees.Group("")
	admin.Use(RoleMiddleware(string(domain.RoleSuperAdmin), string(domain.RoleHRAdmin)))
	{
		admin.GET("", h.GetEmployees)
		admin.POST("", h.CreateEmployee)
		admin.PUT("/:id", h.UpdateEmployee)
		admin.DELETE("/:id", h.DeleteEmployee)
	}
}

func (h *EmployeeHandler) GetEmployees(c *gin.Context) {
	res, err := h.employeeUsecase.GetEmployees()
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get employees: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Employees fetched successfully", res)
}

func (h *EmployeeHandler) CreateEmployee(c *gin.Context) {
	var req usecase.CreateEmployeeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	// Automatically use company ID from JWT claims
	if companyID, exists := c.Get("companyID"); exists {
		cid := companyID.(uuid.UUID)
		if cid != uuid.Nil {
			req.CompanyID = &cid
		}
	}

	if err := h.employeeUsecase.CreateEmployee(&req); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to create employee: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "Employee created successfully", nil)
}

func (h *EmployeeHandler) UpdateEmployee(c *gin.Context) {
	idParam := c.Param("id")
	employeeID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid Employee ID")
		return
	}

	var req usecase.UpdateEmployeeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.employeeUsecase.UpdateEmployee(employeeID, &req); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to update employee: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Employee updated successfully", nil)
}

func (h *EmployeeHandler) DeleteEmployee(c *gin.Context) {
	idParam := c.Param("id")
	employeeID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid Employee ID")
		return
	}

	if err := h.employeeUsecase.DeleteEmployee(employeeID); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to delete employee: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Employee deleted successfully", nil)
}

func (h *EmployeeHandler) GetProfile(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	employee, err := h.employeeUsecase.GetEmployeeByUserID(userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get profile: "+err.Error())
		return
	}
	if employee == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "Employee record not found")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Profile fetched successfully", employee)
}

func (h *EmployeeHandler) UpdateProfile(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	var req usecase.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.employeeUsecase.UpdateProfile(userID, &req); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to update profile: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Profile updated successfully", nil)
}

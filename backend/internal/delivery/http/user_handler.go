package http

import (
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type UserHandler struct {
	db           *gorm.DB
	employeeRepo repository.EmployeeRepository
}

func NewUserHandler(db *gorm.DB, employeeRepo repository.EmployeeRepository) *UserHandler {
	return &UserHandler{
		db:           db,
		employeeRepo: employeeRepo,
	}
}

func (h *UserHandler) SetupRoutes(router *gin.RouterGroup) {
	users := router.Group("/users")

	// Open to authenticated users initially
	users.POST("/face-register", h.RegisterFace)
	users.POST("/change-password", h.ChangePassword)

	// Admin only
	admin := users.Group("")
	admin.Use(RoleMiddleware(string(domain.RoleSuperAdmin), string(domain.RoleHRAdmin)))
	{
		admin.GET("", h.GetUsers)
		admin.GET("/:id", h.GetUserByID)
		admin.POST("", h.CreateUser)
		admin.PUT("/:id", h.UpdateUser)
		admin.DELETE("/:id", h.DeleteUser)
	}
}

func (h *UserHandler) GetUsers(c *gin.Context) {
	var users []domain.User
	if err := h.db.Omit("PasswordHash").Find(&users).Error; err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get users")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Users fetched successfully", users)
}

// CreateUserRequest defines the request body for creating a user
type CreateUserRequest struct {
	Email    string      `json:"email" binding:"required,email"`
	Password string      `json:"password" binding:"required"`
	Role     domain.Role `json:"role" binding:"required"`
	IsActive bool        `json:"isActive"`
}

func (h *UserHandler) CreateUser(c *gin.Context) {
	var req CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	user := domain.User{
		Email:    req.Email,
		Role:     req.Role,
		IsActive: req.IsActive,
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to hash password")
		return
	}
	user.PasswordHash = string(hashedPassword)

	if err := h.db.Create(&user).Error; err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to create user")
		return
	}

	user.PasswordHash = "" // hide
	utils.SuccessResponse(c, http.StatusCreated, "User created successfully", gin.H{"data": user})
}

func (h *UserHandler) GetUserByID(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid ID format")
		return
	}

	var user domain.User
	if err := h.db.Omit("PasswordHash").Where("id = ?", id).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.ErrorResponse(c, http.StatusNotFound, "User not found")
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to fetch user")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "User fetched successfully", gin.H{"data": user})
}

// UpdateUserRequest defines the request body for updating a user
type UpdateUserRequest struct {
	Email    string      `json:"email" binding:"required,email"`
	Password string      `json:"password"` // optional
	Role     domain.Role `json:"role" binding:"required"`
	IsActive bool        `json:"isActive"`
}

func (h *UserHandler) UpdateUser(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid ID format")
		return
	}

	var req UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	var user domain.User
	if err := h.db.Where("id = ?", id).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.ErrorResponse(c, http.StatusNotFound, "User not found")
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to find user")
		return
	}

	user.Email = req.Email
	user.Role = req.Role
	user.IsActive = req.IsActive

	if req.Password != "" {
		hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			utils.ErrorResponse(c, http.StatusInternalServerError, "failed to hash password")
			return
		}
		user.PasswordHash = string(hashed)
	}

	if err := h.db.Save(&user).Error; err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to update user")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "User updated successfully", gin.H{"data": nil})
}

func (h *UserHandler) DeleteUser(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid ID format")
		return
	}

	err = h.db.Transaction(func(tx *gorm.DB) error {
		// 1. Find the employee associated with this user
		var employee domain.Employee
		if err := tx.Where("user_id = ?", id).First(&employee).Error; err == nil {
			// Found employee, use the repository's robust delete method
			if err := h.employeeRepo.Delete(employee.ID); err != nil {
				return err
			}
		}

		// 2. Finally delete the user
		if err := tx.Where("id = ?", id).Delete(&domain.User{}).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		fmt.Printf("Error deleting user %s: %v\n", id, err)
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to delete user and associated data")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "User and all associated data deleted successfully", nil)
}

type RegisterFaceRequest struct {
	Embedding domain.FloatArray `json:"embedding" binding:"required"`
	Selfie    string            `json:"selfie" binding:"required"` // Base64 string
}

func (h *UserHandler) RegisterFace(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	var req RegisterFaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	employee, err := h.employeeRepo.FindByUserID(userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get employee record")
		return
	}
	if employee == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "Employee record not found")
		return
	}

	// Process Selfie Upload
	uploadDir := "uploads/faces"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to create upload directory")
		return
	}

	imageData, err := base64.StdEncoding.DecodeString(req.Selfie)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid selfie image data")
		return
	}

	compressedData, err := utils.CompressImage(imageData, 800, 75)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to compress image")
		return
	}

	filename := fmt.Sprintf("%s_%d.jpg", employee.ID.String(), time.Now().Unix())
	filePath := filepath.Join(uploadDir, filename)

	if err := os.WriteFile(filePath, compressedData, 0644); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to save image")
		return
	}

	employee.FaceEmbedding = req.Embedding
	employee.FaceReferenceURL = "/" + filePath
	employee.IsFaceRegistered = true

	if err := h.employeeRepo.Update(employee); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to save face embedding")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Face registered successfully", nil)
}

type ChangePasswordRequest struct {
	OldPassword string `json:"oldPassword" binding:"required"`
	NewPassword string `json:"newPassword" binding:"required,min=6"`
}

func (h *UserHandler) ChangePassword(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	var user domain.User
	if err := h.db.Where("id = ?", userID).First(&user).Error; err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to find user")
		return
	}

	// Verify old password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.OldPassword)); err != nil {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Password lama tidak sesuai")
		return
	}

	// Hash new password
	hashed, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to hash new password")
		return
	}

	if err := h.db.Model(&user).Update("password_hash", string(hashed)).Error; err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to update password")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Password berhasil diperbarui", nil)
}

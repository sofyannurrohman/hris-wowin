package usecase

import (
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
	"golang.org/x/crypto/bcrypt"
)

type AuthUseCase interface {
	Register(req RegisterRequest) error
	Login(req LoginRequest, secret string) (*LoginResponse, error)
}

type authUseCase struct {
	userRepo    repository.UserRepository
	companyRepo repository.CompanyRepository
}

func NewAuthUseCase(userRepo repository.UserRepository, companyRepo repository.CompanyRepository) AuthUseCase {
	return &authUseCase{userRepo, companyRepo}
}

type RegisterRequest struct {
	Name          string            `json:"name" binding:"required"`
	Email         string            `json:"email" binding:"required,email"`
	EmployeeID    string            `json:"employee_id" binding:"required"`
	Password      string            `json:"password" binding:"required,min=6"`
	JobPositionID string            `json:"job_position_id" binding:"required"`
	BranchID      string            `json:"branch_id" binding:"required"`
	FaceEmbedding domain.FloatArray `json:"face_embedding"`
	Selfie        string            `json:"selfie"` // Base64
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	AccessToken  string       `json:"token"` // Changed to "token" to match frontend
	RefreshToken string       `json:"refresh_token"`
	User         UserResponse `json:"user"`
}

type UserResponse struct {
	ID    string `json:"id"`
	Email string `json:"email"`
	Role  string `json:"role"`
}

func (u *authUseCase) Register(req RegisterRequest) error {
	existing, _ := u.userRepo.FindByEmail(req.Email)
	if existing != nil {
		return errors.New("email already registered")
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	user := &domain.User{
		Email:        req.Email,
		PasswordHash: string(hashed),
		Role:         domain.RoleEmployee, // Default role
		IsActive:     true,
	}

	// Default company to "PT Wowin Purnomo Putera" as requested
	defaultCompany, err := u.companyRepo.FindByName("PT Wowin Purnomo Putera")
	if err == nil && defaultCompany != nil {
		user.CompanyID = &defaultCompany.ID
	}

	jobPosID, err := uuid.Parse(req.JobPositionID)
	if err != nil {
		return errors.New("invalid job position ID format")
	}

	branchID, err := uuid.Parse(req.BranchID)
	if err != nil {
		return errors.New("invalid branch ID format")
	}

	employee := &domain.Employee{
		FirstName:        req.Name,
		EmployeeIDNumber: req.EmployeeID,
		JobPositionID:    &jobPosID,
		BranchID:         &branchID,
		JoinDate:         time.Now(),
		CompanyID:        user.CompanyID, // Inherit from user
	}

	// Handle Face Data if provided
	if req.Selfie != "" && len(req.FaceEmbedding) > 0 {
		uploadDir := "uploads/faces"
		_ = os.MkdirAll(uploadDir, 0755)

		imageData, err := base64.StdEncoding.DecodeString(req.Selfie)
		if err == nil {
			compressedData, err := utils.CompressImage(imageData, 800, 75)
			if err == nil {
				filename := fmt.Sprintf("reg_%s_%d.jpg", req.EmployeeID, time.Now().Unix())
				filePath := filepath.Join(uploadDir, filename)
				if err := os.WriteFile(filePath, compressedData, 0644); err == nil {
					employee.FaceEmbedding = req.FaceEmbedding
					employee.FaceReferenceURL = "/" + filePath
					employee.IsFaceRegistered = true
				}
			}
		}
	}

	return u.userRepo.CreateWithEmployee(user, employee)
}

func (u *authUseCase) Login(req LoginRequest, secret string) (*LoginResponse, error) {
	user, err := u.userRepo.FindByEmail(req.Email)
	if err != nil {
		return nil, errors.New("invalid email or password")
	}

	if !user.IsActive {
		return nil, errors.New("user is inactive")
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password))
	if err != nil {
		return nil, errors.New("invalid email or password")
	}

	companyID := uuid.Nil
	if user.CompanyID != nil {
		companyID = *user.CompanyID
	}

	accessToken, refreshToken, err := utils.GenerateTokens(user.ID, companyID, string(user.Role), secret)
	if err != nil {
		return nil, errors.New("failed to generate token")
	}

	return &LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User: UserResponse{
			ID:    user.ID.String(),
			Email: user.Email,
			Role:  string(user.Role),
		},
	}, nil
}

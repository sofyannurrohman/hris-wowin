package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/sofyan/hris_wowin/backend/config"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

type AuthHandler struct {
	authUseCase usecase.AuthUseCase
	cfg         config.Config
}

func NewAuthHandler(authUseCase usecase.AuthUseCase, cfg config.Config) *AuthHandler {
	return &AuthHandler{
		authUseCase: authUseCase,
		cfg:         cfg,
	}
}

func (h *AuthHandler) SetupRoutes(router *gin.RouterGroup) {
	router.POST("/register", h.Register)
	router.POST("/login", h.Login)
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req usecase.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	err := h.authUseCase.Register(req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "User registered successfully", nil)
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req usecase.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	res, err := h.authUseCase.Login(req, h.cfg.JWTSecret)
	if err != nil {
		utils.ErrorResponse(c, http.StatusUnauthorized, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Login successful", res)
}

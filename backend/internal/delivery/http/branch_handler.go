package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type BranchHandler struct {
	useCase usecase.BranchUseCase
}

func NewBranchHandler(useCase usecase.BranchUseCase) *BranchHandler {
	return &BranchHandler{useCase: useCase}
}

func (h *BranchHandler) SetupRoutes(r *gin.RouterGroup) {
	branches := r.Group("/branches")
	{
		branches.POST("", h.Create)
		branches.GET("/:id", h.GetByID)
		branches.PUT("/:id", h.Update)
		branches.DELETE("/:id", h.Delete)
	}
}

func (h *BranchHandler) SetupPublicRoutes(r *gin.RouterGroup) {
	r.GET("/branches", h.GetAll)
}

func (h *BranchHandler) Create(c *gin.Context) {
	var req usecase.CreateBranchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.useCase.CreateBranch(&req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Branch created successfully"})
}

func (h *BranchHandler) GetAll(c *gin.Context) {
	branches, err := h.useCase.GetBranches()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": branches})
}

func (h *BranchHandler) GetByID(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID format"})
		return
	}

	branch, err := h.useCase.GetBranchByID(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if branch == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Branch not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": branch})
}

func (h *BranchHandler) Update(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID format"})
		return
	}

	var req usecase.UpdateBranchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.useCase.UpdateBranch(id, &req); err != nil {
		if err.Error() == "branch not found" {
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Branch updated successfully"})
}

func (h *BranchHandler) Delete(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID format"})
		return
	}

	if err := h.useCase.DeleteBranch(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Branch deleted successfully"})
}

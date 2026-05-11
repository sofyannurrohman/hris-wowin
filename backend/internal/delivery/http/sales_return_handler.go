package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

type SalesReturnHandler struct {
	returnUsecase  usecase.SalesReturnUsecase
	employeeUseCase usecase.EmployeeUsecase
}

func NewSalesReturnHandler(ru usecase.SalesReturnUsecase, eu usecase.EmployeeUsecase) *SalesReturnHandler {
	return &SalesReturnHandler{ru, eu}
}


func (h *SalesReturnHandler) RegisterRoutes(router *gin.RouterGroup) {
	ret := router.Group("/sales-returns")
	{
		ret.GET("", h.GetByBranch)
		ret.GET("/:id", h.GetByID)
		ret.POST("", h.CreateReturn)
		ret.PATCH("/:id/approve", h.ApproveReturn)
	}
}

func (h *SalesReturnHandler) CreateReturn(c *gin.Context) {
	var req usecase.CreateReturnRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Resolve EmployeeID
	if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		emp, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && emp != nil {
			req.EmployeeID = emp.ID
		}
	}

	ret, err := h.returnUsecase.CreateReturn(req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"data": ret})
}

func (h *SalesReturnHandler) ApproveReturn(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	var approvedByID uuid.UUID
	if userIDStr, exists := c.Get("userID"); exists {
		userID := userIDStr.(uuid.UUID)
		emp, err := h.employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && emp != nil {
			approvedByID = emp.ID
		}
	}

	if err := h.returnUsecase.ApproveReturn(id, approvedByID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Retur berhasil disetujui, stok karantina bertambah dan tagihan disesuaikan"})
}

func (h *SalesReturnHandler) GetByBranch(c *gin.Context) {
	branchID, _ := uuid.Parse(c.Query("branch_id"))
	status := c.Query("status")
	returns, err := h.returnUsecase.GetByBranch(branchID, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": returns})
}

func (h *SalesReturnHandler) GetByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}
	ret, err := h.returnUsecase.GetByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Retur tidak ditemukan"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": ret})
}

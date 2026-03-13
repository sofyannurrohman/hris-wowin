package http

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

type AttendanceHandler struct {
	attendanceUseCase usecase.AttendanceUseCase
}

func NewAttendanceHandler(attendanceUseCase usecase.AttendanceUseCase) *AttendanceHandler {
	return &AttendanceHandler{attendanceUseCase}
}

func (h *AttendanceHandler) SetupRoutes(router *gin.RouterGroup) {
	attendance := router.Group("/attendance")
	{
		attendance.POST("/checkin", h.CheckIn)
		attendance.POST("/checkout", h.CheckOut)
		attendance.GET("/history", h.GetHistory)
		attendance.GET("/stats", h.GetStats)

		admin := attendance.Group("")
		admin.Use(RoleMiddleware(string(domain.RoleSuperAdmin), string(domain.RoleHRAdmin)))
		{
			admin.GET("/all", h.GetAllHistory)
			admin.POST("/manual", h.CreateManual)
			admin.PUT("/:id", h.UpdateAttendance)
			admin.DELETE("/:id", h.DeleteAttendance)
		}
	}
	router.Static("/uploads", "./uploads")
}

func (h *AttendanceHandler) CheckIn(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	var req usecase.CheckInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	att, err := h.attendanceUseCase.CheckIn(userID, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "Check-in successful", att)
}

func (h *AttendanceHandler) CheckOut(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	var req usecase.CheckOutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	att, err := h.attendanceUseCase.CheckOut(userID, req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Check-out successful", att)
}

func (h *AttendanceHandler) GetHistory(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	history, err := h.attendanceUseCase.GetHistory(userID, startDate, endDate)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get history")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Attendance history fetched", history)
}

func (h *AttendanceHandler) GetStats(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userID := userIDStr.(uuid.UUID)

	stats, err := h.attendanceUseCase.GetStats(userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get stats: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Attendance stats fetched", stats)
}

func (h *AttendanceHandler) GetAllHistory(c *gin.Context) {
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "10")

	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)

	history, err := h.attendanceUseCase.GetAllHistory(page, limit)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get all attendance history")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "All attendance history fetched", history)
}

func (h *AttendanceHandler) CreateManual(c *gin.Context) {
	var req usecase.ManualAttendanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	att, err := h.attendanceUseCase.CreateManual(req)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to create manual attendance: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "Manual attendance created successfully", att)
}

func (h *AttendanceHandler) UpdateAttendance(c *gin.Context) {
	idParam := c.Param("id")
	attendanceID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid Attendance ID")
		return
	}

	var req usecase.UpdateAttendanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.attendanceUseCase.UpdateAttendance(attendanceID, req); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to update attendance: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Attendance updated successfully", nil)
}

func (h *AttendanceHandler) DeleteAttendance(c *gin.Context) {
	idParam := c.Param("id")
	attendanceID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid Attendance ID")
		return
	}

	if err := h.attendanceUseCase.DeleteAttendance(attendanceID); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to delete attendance: "+err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Attendance deleted successfully", nil)
}

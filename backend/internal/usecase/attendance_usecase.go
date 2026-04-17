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
)

type AttendanceUseCase interface {
	CheckIn(userID uuid.UUID, req CheckInRequest) (*domain.AttendanceLog, error)
	CheckOut(userID uuid.UUID, req CheckOutRequest) (*domain.AttendanceLog, error)
	GetHistory(userID uuid.UUID, startDate, endDate string) ([]AttendanceHistoryResponse, error)
	GetStats(userID uuid.UUID) (*AttendanceStatsResponse, error)
	GetAllHistory(page, limit int, branchID *uuid.UUID, month string) ([]domain.AttendanceLog, error)
	CreateManual(req ManualAttendanceRequest) (*domain.AttendanceLog, error)
	UpdateAttendance(id uuid.UUID, req UpdateAttendanceRequest) error
	DeleteAttendance(id uuid.UUID) error
}

type attendanceUseCase struct {
	repo         repository.AttendanceRepository
	employeeRepo repository.EmployeeRepository
}

func NewAttendanceUseCase(repo repository.AttendanceRepository, employeeRepo repository.EmployeeRepository) AttendanceUseCase {
	return &attendanceUseCase{
		repo:         repo,
		employeeRepo: employeeRepo,
	}
}

type CheckInRequest struct {
	Latitude      float64   `json:"latitude" binding:"required"`
	Longitude     float64   `json:"longitude" binding:"required"`
	Selfie        string    `json:"selfie"` // Base64 string
	FaceEmbedding []float32 `json:"face_embedding" binding:"required"`
}

type CheckOutRequest struct {
	Latitude      float64   `json:"latitude" binding:"required"`
	Longitude     float64   `json:"longitude" binding:"required"`
	Selfie        string    `json:"selfie" binding:"required"`
	FaceEmbedding []float32 `json:"face_embedding" binding:"required"`
}

type AttendanceHistoryResponse struct {
	ID           string     `json:"id"`
	UserID       string     `json:"user_id"`
	CheckIn      time.Time  `json:"check_in"`
	CheckOut     *time.Time `json:"check_out"`
	Status       string     `json:"status"`
	SelfieURL    string     `json:"selfie_url"`
	WorkDuration int        `json:"work_duration"`
}

type AttendanceStatsResponse struct {
	TotalHours     float64 `json:"total_hours"`
	OvertimeHours  float64 `json:"overtime_hours"`
	AttendanceDays int     `json:"attendance_days"`
	LeaveDays      int     `json:"leave_days"`
}

type ManualAttendanceRequest struct {
	EmployeeID   string `json:"employee_id" binding:"required"`
	ClockInTime  string `json:"clock_in_time" binding:"required"` // Format: YYYY-MM-DDTHH:mm:ssZ
	ClockOutTime string `json:"clock_out_time"`
	Status       string `json:"status" binding:"required"`
	Notes        string `json:"notes"`
}

type UpdateAttendanceRequest struct {
	ClockInTime  string `json:"clock_in_time"`
	ClockOutTime string `json:"clock_out_time"`
	Status       string `json:"status"`
	Notes        string `json:"notes"`
}

func (u *attendanceUseCase) CheckIn(userID uuid.UUID, req CheckInRequest) (*domain.AttendanceLog, error) {
	// 1. Resolve Employee from UserID
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return nil, err
	}
	if employee == nil {
		return nil, errors.New("employee record not found for this user")
	}

	// 2. Validate Geofencing
	if employee.Branch == nil {
		return nil, errors.New("employee branch not found")
	}

	distance := utils.CalculateDistance(req.Latitude, req.Longitude, employee.Branch.Latitude, employee.Branch.Longitude)
	if int(distance) > employee.Branch.RadiusMeter {
		return nil, fmt.Errorf("outside office radius. Distance: %dm, Allowed: %dm", int(distance), employee.Branch.RadiusMeter)
	}

	// 3. Validate AI Face Match
	if !employee.IsFaceRegistered || len(employee.FaceEmbedding) == 0 {
		return nil, errors.New("wajah Anda belum teregistrasi di sistem")
	}

	faceDistance, err := utils.CalculateEuclideanDistance(employee.FaceEmbedding, req.FaceEmbedding)
	if err != nil {
		return nil, errors.New("gagal memvalidasi data pengenalan wajah")
	}

	// Threshold MLKit embeddings (generally distances > 1.0 indicates a mismatch)
	if faceDistance > 1.0 {
		return nil, fmt.Errorf("wajah tidak cocok (distance: %.2f)", faceDistance)
	}

	// 4. Check if already checked in today
	existing, err := u.repo.FindTodayByUserID(employee.ID)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("already checked in today")
	}

	// 4. Handle Selfie Upload if provided
	var selfieURL string
	if req.Selfie != "" {
		// Ensure directory exists
		uploadDir := "uploads/selfies"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			return nil, err
		}

		// Decode base64
		imageData, err := base64.StdEncoding.DecodeString(req.Selfie)
		if err != nil {
			return nil, errors.New("invalid selfie image data")
		}

		// Compress image
		compressedData, err := utils.CompressImage(imageData, 800, 75)
		if err != nil {
			return nil, errors.New("failed to compress image")
		}

		// Generate filename
		filename := fmt.Sprintf("%s_%d.jpg", employee.ID.String(), time.Now().Unix())
		filePath := filepath.Join(uploadDir, filename)

		// Save to file
		if err := os.WriteFile(filePath, compressedData, 0644); err != nil {
			return nil, err
		}

		selfieURL = "/" + filePath
	}

	// 5. Evaluate 'late' status (e.g. late if > 08:15 UTC local)
	// Usually checking local time depends on timezone of user, assuming UTC for MVP.
	now := time.Now().UTC()
	cutoff := time.Date(now.Year(), now.Month(), now.Day(), 8, 15, 0, 0, time.UTC)

	status := "ON_TIME"
	if now.After(cutoff) {
		status = "LATE"
	}

	attendance := &domain.AttendanceLog{
		EmployeeID:      employee.ID,
		ClockInTime:     &now,
		ClockInLat:      req.Latitude,
		ClockInLong:     req.Longitude,
		Status:          status,
		ClockInPhotoURL: selfieURL,
	}

	if err := u.repo.Create(attendance); err != nil {
		return nil, err
	}
	return attendance, nil
}

func (u *attendanceUseCase) CheckOut(userID uuid.UUID, req CheckOutRequest) (*domain.AttendanceLog, error) {
	// 1. Resolve Employee from UserID
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return nil, err
	}
	if employee == nil {
		return nil, errors.New("employee record not found for this user")
	}

	// 2. Validate Geofencing
	if employee.Branch == nil {
		return nil, errors.New("employee branch not found")
	}

	distance := utils.CalculateDistance(req.Latitude, req.Longitude, employee.Branch.Latitude, employee.Branch.Longitude)
	if int(distance) > employee.Branch.RadiusMeter {
		return nil, fmt.Errorf("berada di luar radius kantor. Jarak: %dm, Diizinkan: %dm", int(distance), employee.Branch.RadiusMeter)
	}

	// 3. Validate AI Face Match
	if !employee.IsFaceRegistered || len(employee.FaceEmbedding) == 0 {
		return nil, errors.New("wajah Anda belum teregistrasi di sistem")
	}

	faceDistance, err := utils.CalculateEuclideanDistance(employee.FaceEmbedding, req.FaceEmbedding)
	if err != nil {
		return nil, errors.New("gagal memvalidasi data pengenalan wajah")
	}

	// Threshold MLKit embeddings
	if faceDistance > 1.0 {
		return nil, fmt.Errorf("wajah tidak cocok (distance: %.2f)", faceDistance)
	}

	// 4. Find today's attendance
	existing, err := u.repo.FindTodayByUserID(employee.ID)
	if err != nil {
		return nil, err
	}
	if existing == nil {
		return nil, errors.New("anda belum melakukan absen masuk (clock in) hari ini")
	}
	if existing.ClockOutTime != nil {
		return nil, errors.New("anda sudah melakukan absen pulang hari ini")
	}

	// 4. Handle Selfie Upload if provided
	var selfieURL string
	if req.Selfie != "" {
		// Ensure directory exists
		uploadDir := "uploads/selfies"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			return nil, err
		}

		// Decode base64
		imageData, err := base64.StdEncoding.DecodeString(req.Selfie)
		if err != nil {
			return nil, errors.New("invalid selfie image data")
		}

		// Compress image
		compressedData, err := utils.CompressImage(imageData, 800, 75)
		if err != nil {
			return nil, errors.New("failed to compress image")
		}

		// Generate filename
		filename := fmt.Sprintf("%s_%d_out.jpg", employee.ID.String(), time.Now().Unix())
		filePath := filepath.Join(uploadDir, filename)

		// Save to file
		if err := os.WriteFile(filePath, compressedData, 0644); err != nil {
			return nil, err
		}

		selfieURL = "/" + filePath
	} else {
		return nil, errors.New("foto absen pulang wajib dilampirkan")
	}

	now := time.Now().UTC()

	existing.ClockOutTime = &now
	existing.ClockOutLat = req.Latitude
	existing.ClockOutLong = req.Longitude
	existing.ClockOutPhotoURL = selfieURL

	if err := u.repo.Update(existing); err != nil {
		return nil, errors.New("gagal menyimpan data absen pulang")
	}
	return existing, nil
}

func (u *attendanceUseCase) GetHistory(userID uuid.UUID, startDate, endDate string) ([]AttendanceHistoryResponse, error) {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return nil, err
	}
	if employee == nil {
		return nil, errors.New("employee record not found")
	}

	// 1. Set default date range jika kosong (Bulan Berjalan)
	now := time.Now()
	var start, end time.Time

	if startDate == "" {
		start = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
	} else {
		start, _ = time.Parse("2006-01-02", startDate)
	}

	if endDate == "" {
		end = now
	} else {
		parsedEnd, _ := time.Parse("2006-01-02", endDate)
		end = time.Date(parsedEnd.Year(), parsedEnd.Month(), parsedEnd.Day(), 23, 59, 59, 0, now.Location())
	}

	// 2. Ambil data dari Repository
	logs, err := u.repo.FindHistoryByDateRange(employee.ID, start, end)
	if err != nil {
		return nil, errors.New("gagal mengambil riwayat absensi")
	}

	// 3. Mapping data dari Entitas Database (AttendanceLog) ke DTO (AttendanceHistoryResponse)
	var history []AttendanceHistoryResponse
	for _, log := range logs {
		checkIn := time.Time{}
		if log.ClockInTime != nil {
			checkIn = *log.ClockInTime
		}
		history = append(history, AttendanceHistoryResponse{
			ID:        log.ID.String(),
			UserID:    log.EmployeeID.String(),
			CheckIn:   checkIn,
			CheckOut:  log.ClockOutTime,
			Status:    log.Status,
			SelfieURL: log.ClockInPhotoURL,
		})
	}

	// Jika kosong, kembalikan array kosong (bukan null) agar Flutter mudah memprosesnya
	if history == nil {
		history = []AttendanceHistoryResponse{}
	}

	return history, nil
}

func (u *attendanceUseCase) GetStats(userID uuid.UUID) (*AttendanceStatsResponse, error) {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return nil, err
	}
	if employee == nil {
		return nil, errors.New("employee record not found")
	}

	// For simplicity, get current month stats
	now := time.Now()
	start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	end := now

	logs, err := u.repo.FindHistoryByDateRange(employee.ID, start, end)
	if err != nil {
		return nil, err
	}

	stats := &AttendanceStatsResponse{
		AttendanceDays: len(logs),
	}

	var totalDuration time.Duration
	for _, log := range logs {
		if log.ClockInTime != nil && log.ClockOutTime != nil {
			duration := log.ClockOutTime.Sub(*log.ClockInTime)
			totalDuration += duration
		}
	}

	stats.TotalHours = totalDuration.Hours()
	// Dummy for now until Leave/Overtime integrated correctly
	stats.OvertimeHours = 0
	stats.LeaveDays = 0

	return stats, nil
}

func (u *attendanceUseCase) GetAllHistory(page, limit int, branchID *uuid.UUID, month string) ([]domain.AttendanceLog, error) {
	var offset int
	if limit > 0 {
		if page < 1 {
			page = 1
		}
		offset = (page - 1) * limit
	}
	return u.repo.FindAllHistory(limit, offset, branchID, month)
}

func (u *attendanceUseCase) CreateManual(req ManualAttendanceRequest) (*domain.AttendanceLog, error) {
	employeeID, err := uuid.Parse(req.EmployeeID)
	if err != nil {
		return nil, errors.New("invalid employee ID")
	}

	clockIn, err := time.Parse(time.RFC3339, req.ClockInTime)
	if err != nil {
		return nil, errors.New("invalid clock_in_time format. Use RFC3339 (e.g. 2026-03-06T08:00:00Z)")
	}

	var clockOut *time.Time
	if req.ClockOutTime != "" {
		parsedOut, err := time.Parse(time.RFC3339, req.ClockOutTime)
		if err != nil {
			return nil, errors.New("invalid clock_out_time format")
		}
		clockOut = &parsedOut
	}

	log := &domain.AttendanceLog{
		EmployeeID:   employeeID,
		ClockInTime:  &clockIn,
		ClockOutTime: clockOut,
		Status:       req.Status,
		Notes:        req.Notes,
	}

	if err := u.repo.Create(log); err != nil {
		return nil, err
	}
	return log, nil
}

func (u *attendanceUseCase) UpdateAttendance(id uuid.UUID, req UpdateAttendanceRequest) error {
	log, err := u.repo.FindByID(id)
	if err != nil {
		return err
	}
	if log == nil {
		return errors.New("attendance log not found")
	}

	if req.ClockInTime != "" {
		clockIn, err := time.Parse(time.RFC3339, req.ClockInTime)
		if err != nil {
			return errors.New("invalid clock_in_time format")
		}
		log.ClockInTime = &clockIn
	}

	if req.ClockOutTime != "" {
		clockOut, err := time.Parse(time.RFC3339, req.ClockOutTime)
		if err != nil {
			return errors.New("invalid clock_out_time format")
		}
		log.ClockOutTime = &clockOut
	} else if req.ClockOutTime == "null" {
		log.ClockOutTime = nil
	}

	if req.Status != "" {
		log.Status = req.Status
	}
	if req.Notes != "" {
		log.Notes = req.Notes
	}

	return u.repo.Update(log)
}

func (u *attendanceUseCase) DeleteAttendance(id uuid.UUID) error {
	return u.repo.Delete(id)
}

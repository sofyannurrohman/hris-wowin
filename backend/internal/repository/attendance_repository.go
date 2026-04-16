package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type AttendanceRepository interface {
	Create(attendance *domain.AttendanceLog) error
	Update(attendance *domain.AttendanceLog) error
	FindTodayByUserID(userID uuid.UUID) (*domain.AttendanceLog, error)
	FindHistoryByUserID(userID uuid.UUID, limit, offset int) ([]domain.AttendanceLog, error)
	FindHistoryByDateRange(employeeID uuid.UUID, startDate, endDate time.Time) ([]domain.AttendanceLog, error)
	FindAllHistory(limit, offset int, branchID *uuid.UUID, month string) ([]domain.AttendanceLog, error)
	FindByID(id uuid.UUID) (*domain.AttendanceLog, error)
	Delete(id uuid.UUID) error
}

type attendanceRepository struct {
	db *gorm.DB
}

func NewAttendanceRepository(db *gorm.DB) AttendanceRepository {
	return &attendanceRepository{db}
}

func (r *attendanceRepository) Create(attendance *domain.AttendanceLog) error {
	return r.db.Create(attendance).Error
}

func (r *attendanceRepository) Update(attendance *domain.AttendanceLog) error {
	return r.db.Save(attendance).Error
}

func (r *attendanceRepository) FindTodayByUserID(userID uuid.UUID) (*domain.AttendanceLog, error) {
	var attendance domain.AttendanceLog
	now := time.Now().UTC()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	endOfDay := startOfDay.Add(24 * time.Hour)

	err := r.db.Where("employee_id = ? AND clock_in_time >= ? AND clock_in_time < ?", userID, startOfDay, endOfDay).First(&attendance).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil // Return nil, nil if not found today
		}
		return nil, err
	}
	return &attendance, nil
}

func (r *attendanceRepository) FindHistoryByUserID(employeeID uuid.UUID, limit, offset int) ([]domain.AttendanceLog, error) {
	var attendances []domain.AttendanceLog
	err := r.db.Where("employee_id = ?", employeeID).
		Order("clock_in_time DESC").
		Limit(limit).
		Offset(offset).
		Find(&attendances).Error
	return attendances, err
}

func (r *attendanceRepository) FindHistoryByDateRange(employeeID uuid.UUID, startDate, endDate time.Time) ([]domain.AttendanceLog, error) {
	var logs []domain.AttendanceLog
	err := r.db.Where("employee_id = ? AND clock_in_time >= ? AND clock_in_time <= ?", employeeID, startDate, endDate).
		Order("clock_in_time DESC").
		Find(&logs).Error
	return logs, err
}

func (r *attendanceRepository) FindAllHistory(limit, offset int, branchID *uuid.UUID, month string) ([]domain.AttendanceLog, error) {
	var attendances []domain.AttendanceLog
	query := r.db.Preload("Employee.User").Preload("Employee.Branch")
	
	if branchID != nil && *branchID != uuid.Nil {
		query = query.Joins("JOIN employees ON employees.id = attendance_logs.employee_id").Where("employees.branch_id = ?", *branchID)
	}

	if month != "" {
		if t, err := time.Parse("2006-01", month); err == nil {
			start := time.Date(t.Year(), t.Month(), 1, 0, 0, 0, 0, time.UTC)
			end := start.AddDate(0, 1, 0).Add(-time.Second) // End of month
			query = query.Where("attendance_logs.clock_in_time >= ? AND attendance_logs.clock_in_time <= ?", start, end)
		} else if t, err := time.Parse("2006", month); err == nil {
			start := time.Date(t.Year(), 1, 1, 0, 0, 0, 0, time.UTC)
			end := start.AddDate(1, 0, 0).Add(-time.Second) // End of year
			query = query.Where("attendance_logs.clock_in_time >= ? AND attendance_logs.clock_in_time <= ?", start, end)
		}
	}

	if limit > 0 {
		query = query.Limit(limit).Offset(offset)
	}

	err := query.Order("attendance_logs.clock_in_time DESC").Find(&attendances).Error
	return attendances, err
}

func (r *attendanceRepository) FindByID(id uuid.UUID) (*domain.AttendanceLog, error) {
	var attendance domain.AttendanceLog
	err := r.db.Preload("Employee.User").Where("id = ?", id).First(&attendance).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &attendance, nil
}

func (r *attendanceRepository) Delete(id uuid.UUID) error {
	return r.db.Where("id = ?", id).Delete(&domain.AttendanceLog{}).Error
}

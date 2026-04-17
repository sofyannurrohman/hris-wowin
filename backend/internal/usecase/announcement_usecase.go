package usecase

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type AnnouncementUseCase interface {
	GetAnnouncements() ([]domain.Announcement, error)
}

type announcementUseCase struct {
	announcementRepo repository.AnnouncementRepository
	employeeRepo     repository.EmployeeRepository
}

func NewAnnouncementUseCase(announcementRepo repository.AnnouncementRepository, employeeRepo repository.EmployeeRepository) AnnouncementUseCase {
	return &announcementUseCase{
		announcementRepo: announcementRepo,
		employeeRepo:     employeeRepo,
	}
}

func (u *announcementUseCase) GetAnnouncements() ([]domain.Announcement, error) {
	// 1. Get Formal Announcements
	formal, err := u.announcementRepo.FindAll()
	if err != nil {
		return nil, err
	}

	// 2. Get Birthday Announcements
	birthdayEmployees, err := u.employeeRepo.FindBirthdaysToday()
	if err != nil {
		// Log error but don't fail the whole request
		fmt.Printf("Error fetching birthdays: %v\n", err)
	}

	for _, emp := range birthdayEmployees {
		birthdayAnn := domain.Announcement{
			ID:        uuid.New(), // Virtual ID
			Title:     "Selamat Ulang Tahun!",
			Content:   fmt.Sprintf("Selamat ulang tahun untuk %s! Mari berikan ucapan terbaik dan rayakan hari spesial ini bersama tim.", emp.FirstName),
			Category:  "birthday",
			Author:    "System",
			CreatedAt: time.Now(),
		}
		// Prepend to show at the top
		formal = append([]domain.Announcement{birthdayAnn}, formal...)
	}

	return formal, nil
}

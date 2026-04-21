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
	AdminListAnnouncements() ([]domain.Announcement, error)
	CreateAnnouncement(req CreateAnnouncementRequest) error
	UpdateAnnouncement(id uuid.UUID, req UpdateAnnouncementRequest) error
	DeleteAnnouncement(id uuid.UUID) error
}

type CreateAnnouncementRequest struct {
	Title    string `json:"title" binding:"required"`
	Content  string `json:"content" binding:"required"`
	Category string `json:"category" binding:"required"`
}

type UpdateAnnouncementRequest struct {
	Title    string `json:"title" binding:"required"`
	Content  string `json:"content" binding:"required"`
	Category string `json:"category" binding:"required"`
	IsActive bool   `json:"is_active"`
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
	// ... existing logic ...
	formal, err := u.announcementRepo.FindAll()
	if err != nil {
		return nil, err
	}

	birthdayEmployees, err := u.employeeRepo.FindBirthdaysToday()
	if err != nil {
		fmt.Printf("Error fetching birthdays: %v\n", err)
	}

	for _, emp := range birthdayEmployees {
		birthdayAnn := domain.Announcement{
			ID:        uuid.New(),
			Title:     "Selamat Ulang Tahun!",
			Content:   fmt.Sprintf("Selamat ulang tahun untuk %s! Mari berikan ucapan terbaik dan rayakan hari spesial ini bersama tim.", emp.FirstName),
			Category:  "birthday",
			Author:    "System",
			CreatedAt: time.Now(),
		}
		formal = append([]domain.Announcement{birthdayAnn}, formal...)
	}

	return formal, nil
}

func (u *announcementUseCase) AdminListAnnouncements() ([]domain.Announcement, error) {
	return u.announcementRepo.FindAllAdmin()
}

func (u *announcementUseCase) CreateAnnouncement(req CreateAnnouncementRequest) error {
	announcement := &domain.Announcement{
		Title:    req.Title,
		Content:  req.Content,
		Category: req.Category,
		IsActive: true,
	}
	return u.announcementRepo.Create(announcement)
}

func (u *announcementUseCase) UpdateAnnouncement(id uuid.UUID, req UpdateAnnouncementRequest) error {
	announcement, err := u.announcementRepo.FindByID(id)
	if err != nil {
		return err
	}

	announcement.Title = req.Title
	announcement.Content = req.Content
	announcement.Category = req.Category
	announcement.IsActive = req.IsActive

	return u.announcementRepo.Update(announcement)
}

func (u *announcementUseCase) DeleteAnnouncement(id uuid.UUID) error {
	return u.announcementRepo.Delete(id)
}

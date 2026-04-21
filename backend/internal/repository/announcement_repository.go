package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type AnnouncementRepository interface {
	FindAll() ([]domain.Announcement, error)
	FindAllAdmin() ([]domain.Announcement, error)
	FindByID(id uuid.UUID) (*domain.Announcement, error)
	Create(announcement *domain.Announcement) error
	Update(announcement *domain.Announcement) error
	Delete(id uuid.UUID) error
}

type announcementRepository struct {
	db *gorm.DB
}

func NewAnnouncementRepository(db *gorm.DB) AnnouncementRepository {
	return &announcementRepository{db}
}

func (r *announcementRepository) FindAll() ([]domain.Announcement, error) {
	var announcements []domain.Announcement
	if err := r.db.Where("is_active = ?", true).Order("created_at desc").Find(&announcements).Error; err != nil {
		return nil, err
	}
	return announcements, nil
}

func (r *announcementRepository) Create(announcement *domain.Announcement) error {
	return r.db.Create(announcement).Error
}

func (r *announcementRepository) FindAllAdmin() ([]domain.Announcement, error) {
	var announcements []domain.Announcement
	if err := r.db.Order("created_at desc").Find(&announcements).Error; err != nil {
		return nil, err
	}
	return announcements, nil
}

func (r *announcementRepository) FindByID(id uuid.UUID) (*domain.Announcement, error) {
	var announcement domain.Announcement
	if err := r.db.First(&announcement, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &announcement, nil
}

func (r *announcementRepository) Update(announcement *domain.Announcement) error {
	return r.db.Save(announcement).Error
}

func (r *announcementRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&domain.Announcement{}, "id = ?", id).Error
}

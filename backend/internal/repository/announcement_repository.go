package repository

import (
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type AnnouncementRepository interface {
	FindAll() ([]domain.Announcement, error)
	Create(announcement *domain.Announcement) error
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

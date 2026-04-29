package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type BannerOrderRepository interface {
	Create(order *domain.BannerOrder) error
	FindAll() ([]domain.BannerOrder, error)
	FindByID(id uuid.UUID) (*domain.BannerOrder, error)
}

type bannerOrderRepository struct {
	db *gorm.DB
}

func NewBannerOrderRepository(db *gorm.DB) BannerOrderRepository {
	return &bannerOrderRepository{db: db}
}

func (r *bannerOrderRepository) Create(order *domain.BannerOrder) error {
	return r.db.Create(order).Error
}

func (r *bannerOrderRepository) FindAll() ([]domain.BannerOrder, error) {
	var orders []domain.BannerOrder
	err := r.db.Find(&orders).Error
	return orders, err
}

func (r *bannerOrderRepository) FindByID(id uuid.UUID) (*domain.BannerOrder, error) {
	var order domain.BannerOrder
	err := r.db.First(&order, "id = ?", id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &order, nil
}

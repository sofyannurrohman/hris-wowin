package usecase

import (
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
)

type BannerOrderUseCase interface {
	CreateOrder(order *domain.BannerOrder) error
}

type bannerOrderUseCase struct {
	bannerOrderRepo repository.BannerOrderRepository
}

func NewBannerOrderUseCase(bannerOrderRepo repository.BannerOrderRepository) BannerOrderUseCase {
	return &bannerOrderUseCase{
		bannerOrderRepo: bannerOrderRepo,
	}
}

func (u *bannerOrderUseCase) CreateOrder(order *domain.BannerOrder) error {
	order.Status = "PENDING"
	return u.bannerOrderRepo.Create(order)
}

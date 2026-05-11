package repository

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type SalesReturnRepository interface {
	Create(ret *domain.SalesReturn) error
	Update(ret *domain.SalesReturn) error
	FindByID(id uuid.UUID) (*domain.SalesReturn, error)
	FindByBranch(branchID uuid.UUID, status string) ([]domain.SalesReturn, error)
	CountByBranchAndDate(branchID uuid.UUID, date time.Time) (int64, error)
}

type salesReturnRepository struct {
	db *gorm.DB
}

func NewSalesReturnRepository(db *gorm.DB) SalesReturnRepository {
	return &salesReturnRepository{db}
}

func (r *salesReturnRepository) Create(ret *domain.SalesReturn) error {
	return r.db.Create(ret).Error
}

func (r *salesReturnRepository) Update(ret *domain.SalesReturn) error {
	return r.db.Save(ret).Error
}

func (r *salesReturnRepository) FindByID(id uuid.UUID) (*domain.SalesReturn, error) {
	var ret domain.SalesReturn
	err := r.db.
		Preload("Items.Product").
		Preload("SalesOrder").
		Preload("Transaction").
		Preload("Employee").
		First(&ret, "id = ?", id).Error
	return &ret, err
}

func (r *salesReturnRepository) FindByBranch(branchID uuid.UUID, status string) ([]domain.SalesReturn, error) {
	var returns []domain.SalesReturn
	q := r.db.Preload("Items.Product").Preload("SalesOrder").Preload("Employee").Where("branch_id = ?", branchID)
	if status != "" && status != "ALL" {
		q = q.Where("status = ?", status)
	}
	err := q.Order("created_at desc").Find(&returns).Error
	return returns, err
}

func (r *salesReturnRepository) CountByBranchAndDate(branchID uuid.UUID, date time.Time) (int64, error) {
	var count int64
	dateStr := date.Format("2006-01-02")
	err := r.db.Model(&domain.SalesReturn{}).
		Where("branch_id = ? AND DATE(created_at) = ?", branchID, dateStr).
		Count(&count).Error
	return count, err
}

func GenerateReturnNumber(branchID uuid.UUID, date time.Time, count int64) string {
	return fmt.Sprintf("RET-%s-%04d", date.Format("20060102"), count+1)
}

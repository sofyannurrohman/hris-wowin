package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type SalesTransactionRepository interface {
	Create(transaction *domain.SalesTransaction) error
	FindAll() ([]domain.SalesTransaction, error)
	FindByID(id uuid.UUID) (*domain.SalesTransaction, error)
	Update(transaction *domain.SalesTransaction) error
	Delete(id uuid.UUID) error
	GetTransactionsByEmployeeAndPeriod(employeeID uuid.UUID, month, year int) ([]domain.SalesTransaction, error)
}

type salesTransactionRepository struct {
	db *gorm.DB
}

func NewSalesTransactionRepository(db *gorm.DB) SalesTransactionRepository {
	return &salesTransactionRepository{db}
}

func (r *salesTransactionRepository) Create(transaction *domain.SalesTransaction) error {
	return r.db.Create(transaction).Error
}

func (r *salesTransactionRepository) FindAll() ([]domain.SalesTransaction, error) {
	var transactions []domain.SalesTransaction
	if err := r.db.Preload("Company").Preload("Store").Preload("Employee").Find(&transactions).Error; err != nil {
		return nil, err
	}
	return transactions, nil
}

func (r *salesTransactionRepository) FindByID(id uuid.UUID) (*domain.SalesTransaction, error) {
	var transaction domain.SalesTransaction
	if err := r.db.Preload("Company").Preload("Store").Preload("Employee").Where("id = ?", id).First(&transaction).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &transaction, nil
}

func (r *salesTransactionRepository) Update(transaction *domain.SalesTransaction) error {
	return r.db.Save(transaction).Error
}

func (r *salesTransactionRepository) Delete(id uuid.UUID) error {
	return r.db.Where("id = ?", id).Delete(&domain.SalesTransaction{}).Error
}

func (r *salesTransactionRepository) GetTransactionsByEmployeeAndPeriod(employeeID uuid.UUID, month, year int) ([]domain.SalesTransaction, error) {
	var transactions []domain.SalesTransaction
	if err := r.db.Where("employee_id = ? AND period_month = ? AND period_year = ?", employeeID, month, year).Find(&transactions).Error; err != nil {
		return nil, err
	}
	return transactions, nil
}

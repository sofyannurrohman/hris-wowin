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
	FindByReceiptNo(receiptNo string) (*domain.SalesTransaction, error)
	CreatePayment(payment *domain.SalesPayment) error
	GetOutstandingByStore(storeID uuid.UUID) ([]domain.SalesTransaction, error)
	GetByDueDate(date string, employeeID uuid.UUID) ([]domain.SalesTransaction, error)
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

func (r *salesTransactionRepository) FindByReceiptNo(receiptNo string) (*domain.SalesTransaction, error) {
	var transaction domain.SalesTransaction
	if err := r.db.Preload("Company").Preload("Store").Preload("Employee").Where("receipt_no = ?", receiptNo).First(&transaction).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &transaction, nil
}

func (r *salesTransactionRepository) CreatePayment(payment *domain.SalesPayment) error {
	return r.db.Create(payment).Error
}

func (r *salesTransactionRepository) GetOutstandingByStore(storeID uuid.UUID) ([]domain.SalesTransaction, error) {
	var transactions []domain.SalesTransaction
	err := r.db.Preload("Store").Preload("Employee").
		Where("store_id = ? AND payment_status != ?", storeID, domain.PaymentStatusPaid).
		Order("transaction_date ASC").Find(&transactions).Error
	return transactions, err
}

func (r *salesTransactionRepository) GetByDueDate(date string, employeeID uuid.UUID) ([]domain.SalesTransaction, error) {
	var transactions []domain.SalesTransaction
	err := r.db.Preload("Store").Preload("Employee").
		Where("employee_id = ? AND payment_due_date = ? AND payment_status != ?", employeeID, date, domain.PaymentStatusPaid).
		Order("transaction_date ASC").Find(&transactions).Error
	return transactions, err
}

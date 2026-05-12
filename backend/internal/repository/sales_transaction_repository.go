package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
	"time"
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
	FindByStatusAndCompany(status string, companyID uuid.UUID) ([]domain.SalesTransaction, error)
	FindDeliveryPending(companyID uuid.UUID) ([]domain.SalesTransaction, error)
	CountByCompany(companyID uuid.UUID) (int64, error)
	CountByCompanyAndDate(companyID uuid.UUID, date time.Time) (int64, error)
	GetProductSalesDistribution(productID uuid.UUID, companyID uuid.UUID) ([]map[string]interface{}, error)
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
	if err := r.db.Preload("Company").Preload("Store").Preload("Employee").
		Preload("Employee.Company").Preload("Employee.JobPosition").
		Preload("DeliveryItems").Preload("DeliveryItems.DeliveryBatch").
		Preload("Items").Preload("Items.Product").
		Find(&transactions).Error; err != nil {
		return nil, err
	}
	return transactions, nil
}

func (r *salesTransactionRepository) FindByID(id uuid.UUID) (*domain.SalesTransaction, error) {
	var transaction domain.SalesTransaction
	if err := r.db.Preload("Company").Preload("Store").Preload("Employee").
		Preload("Employee.Company").Preload("Employee.JobPosition").
		Preload("Items").Preload("Items.Product").
		Where("id = ?", id).First(&transaction).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &transaction, nil
}

func (r *salesTransactionRepository) Update(transaction *domain.SalesTransaction) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// Delete existing items first
		if err := tx.Where("sales_transaction_id = ?", transaction.ID).Delete(&domain.SalesItem{}).Error; err != nil {
			return err
		}
		// Save the transaction and its new items
		return tx.Save(transaction).Error
	})
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
	if err := r.db.Preload("Company").Preload("Store").Preload("Employee").
		Preload("Employee.Company").Preload("Employee.JobPosition").
		Where("receipt_no = ?", receiptNo).First(&transaction).Error; err != nil {
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

func (r *salesTransactionRepository) FindByStatusAndCompany(status string, companyID uuid.UUID) ([]domain.SalesTransaction, error) {
	var transactions []domain.SalesTransaction
	db := r.db.Preload("Store").Preload("Employee").Preload("Company").
		Preload("Employee.Company").Preload("Employee.JobPosition").
		Preload("DeliveryItems").Preload("DeliveryItems.DeliveryBatch").
		Preload("Items").Preload("Items.Product")
	if status != "" {
		db = db.Where("status = ?", status)
	}
	if companyID != uuid.Nil {
		db = db.Where("company_id = ?", companyID)
	}
	err := db.Order("transaction_date DESC").Find(&transactions).Error
	return transactions, err
}

func (r *salesTransactionRepository) FindDeliveryPending(companyID uuid.UUID) ([]domain.SalesTransaction, error) {
	var transactions []domain.SalesTransaction
	
	// Query transactions with status VERIFIED that are NOT in any delivery_items
	db := r.db.Preload("Store").Preload("Employee").Preload("Company").
		Preload("Employee.Company").Preload("Employee.JobPosition").
		Where("status = ?", "VERIFIED").
		Where("id NOT IN (SELECT sales_transaction_id FROM delivery_items)")

	if companyID != uuid.Nil {
		db = db.Where("company_id = ?", companyID)
	}

	err := db.Order("transaction_date DESC").Find(&transactions).Error
	return transactions, err
}


func (r *salesTransactionRepository) CountByCompany(companyID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.Model(&domain.SalesTransaction{}).Where("company_id = ?", companyID).Count(&count).Error
	return count, err
}

func (r *salesTransactionRepository) CountByCompanyAndDate(companyID uuid.UUID, date time.Time) (int64, error) {
	var count int64
	startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())
	endOfDay := startOfDay.Add(24 * time.Hour)
	err := r.db.Model(&domain.SalesTransaction{}).
		Where("company_id = ? AND transaction_date >= ? AND transaction_date < ?", companyID, startOfDay, endOfDay).
		Count(&count).Error
	return count, err
}

func (r *salesTransactionRepository) GetProductSalesDistribution(productID uuid.UUID, companyID uuid.UUID) ([]map[string]interface{}, error) {
	var results []map[string]interface{}
	
	query := r.db.Table("sales_items si").
		Select("s.id as store_id, s.name as store_name, s.latitude, s.longitude, SUM(si.quantity) as total_quantity").
		Joins("JOIN sales_transactions st ON si.sales_transaction_id = st.id").
		Joins("JOIN stores s ON st.store_id = s.id").
		Where("si.product_id = ? AND st.status = ?", productID, "VERIFIED")

	if companyID != uuid.Nil {
		query = query.Where("st.company_id = ?", companyID)
	}

	err := query.Group("s.id, s.name, s.latitude, s.longitude").Scan(&results).Error
	return results, err
}

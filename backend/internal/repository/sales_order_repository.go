package repository

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type SalesOrderRepository interface {
	Create(so *domain.SalesOrder) error
	Update(so *domain.SalesOrder) error
	FindByID(id uuid.UUID) (*domain.SalesOrder, error)
	FindBySONumber(soNumber string) (*domain.SalesOrder, error)
	FindByBranch(branchID uuid.UUID, status string) ([]domain.SalesOrder, error)
	FindByEmployee(employeeID uuid.UUID) ([]domain.SalesOrder, error)
	CountByBranchAndDate(branchID uuid.UUID, date time.Time) (int64, error)
	Delete(id uuid.UUID) error
	FindWaitingStockByProduct(branchID, productID uuid.UUID) ([]domain.SalesOrder, error)

	// Payment Methods
	AddPayment(payment *domain.SalesPayment) error
	GetPaymentsBySO(soID uuid.UUID) ([]domain.SalesPayment, error)
}


type salesOrderRepository struct {
	db *gorm.DB
}

func NewSalesOrderRepository(db *gorm.DB) SalesOrderRepository {
	return &salesOrderRepository{db}
}

func (r *salesOrderRepository) Create(so *domain.SalesOrder) error {
	return r.db.Create(so).Error
}

func (r *salesOrderRepository) Update(so *domain.SalesOrder) error {
	return r.db.Save(so).Error
}

func (r *salesOrderRepository) FindByID(id uuid.UUID) (*domain.SalesOrder, error) {
	var so domain.SalesOrder
	err := r.db.
		Preload("Items.Product").
		Preload("Items.Batches").
		Preload("Employee").
		Preload("Store").
		Preload("Branch").
		Preload("ConfirmedBy").
		First(&so, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &so, nil
}

func (r *salesOrderRepository) FindBySONumber(soNumber string) (*domain.SalesOrder, error) {
	var so domain.SalesOrder
	err := r.db.
		Preload("Items.Product").
		Preload("Items.Batches").
		Preload("Employee").
		Preload("Store").
		First(&so, "so_number = ?", soNumber).Error
	if err != nil {
		return nil, err
	}
	return &so, nil
}

func (r *salesOrderRepository) FindByBranch(branchID uuid.UUID, status string) ([]domain.SalesOrder, error) {
	var orders []domain.SalesOrder
	q := r.db.
		Preload("Items.Product").
		Preload("Items.Batches").
		Preload("Employee").
		Preload("Store").
		Where("branch_id = ?", branchID)

	if status != "" && status != "ALL" {
		q = q.Where("status = ?", status)
	}

	err := q.Order("created_at desc").Find(&orders).Error
	return orders, err
}

func (r *salesOrderRepository) FindByEmployee(employeeID uuid.UUID) ([]domain.SalesOrder, error) {
	var orders []domain.SalesOrder
	err := r.db.
		Preload("Items.Product").
		Preload("Store").
		Where("employee_id = ?", employeeID).
		Order("created_at desc").
		Find(&orders).Error
	return orders, err
}

func (r *salesOrderRepository) CountByBranchAndDate(branchID uuid.UUID, date time.Time) (int64, error) {
	var count int64
	dateStr := date.Format("2006-01-02")
	err := r.db.Model(&domain.SalesOrder{}).
		Where("branch_id = ? AND DATE(order_date) = ?", branchID, dateStr).
		Count(&count).Error
	return count, err
}

func (r *salesOrderRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&domain.SalesOrder{}, "id = ?", id).Error
}

func (r *salesOrderRepository) FindWaitingStockByProduct(branchID, productID uuid.UUID) ([]domain.SalesOrder, error) {
	var orders []domain.SalesOrder
	err := r.db.
		Preload("Items").
		Joins("JOIN sales_order_items ON sales_order_items.sales_order_id = sales_orders.id").
		Where("sales_orders.branch_id = ? AND sales_orders.status = ? AND sales_order_items.product_id = ?", 
			branchID, domain.SOStatusWaitingStock, productID).
		Order("sales_orders.created_at asc").
		Distinct().
		Find(&orders).Error
	return orders, err
}


// GenerateSONumber generates a unique SO number: SO-YYYYMMDD-NNNN
func GenerateSONumber(branchID uuid.UUID, date time.Time, count int64) string {
	return fmt.Sprintf("SO-%s-%04d", date.Format("20060102"), count+1)
}

func (r *salesOrderRepository) AddPayment(payment *domain.SalesPayment) error {
	return r.db.Create(payment).Error
}

func (r *salesOrderRepository) GetPaymentsBySO(soID uuid.UUID) ([]domain.SalesPayment, error) {
	var payments []domain.SalesPayment
	err := r.db.Where("sales_order_id = ?", soID).Order("created_at asc").Find(&payments).Error
	return payments, err
}

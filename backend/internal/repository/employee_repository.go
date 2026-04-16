package repository

import (
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"gorm.io/gorm"
)

type EmployeeRepository interface {
	Create(employee *domain.Employee) error
	FindAll(limit int) ([]domain.Employee, error)
	FindByID(id uuid.UUID) (*domain.Employee, error)
	FindByUserID(userID uuid.UUID) (*domain.Employee, error)
	Update(employee *domain.Employee) error
	Delete(id uuid.UUID) error
}

type employeeRepository struct {
	db *gorm.DB
}

func NewEmployeeRepository(db *gorm.DB) EmployeeRepository {
	return &employeeRepository{db}
}

func (r *employeeRepository) Create(employee *domain.Employee) error {
	return r.db.Create(employee).Error
}

func (r *employeeRepository) FindAll(limit int) ([]domain.Employee, error) {
	var employees []domain.Employee
	query := r.db.Preload("User").Preload("Branch").Preload("Department").Preload("JobPosition")
	if limit > 0 {
		query = query.Limit(limit)
	}
	if err := query.Find(&employees).Error; err != nil {
		return nil, err
	}
	return employees, nil
}

func (r *employeeRepository) FindByID(id uuid.UUID) (*domain.Employee, error) {
	var employee domain.Employee
	if err := r.db.Preload("User").Preload("Branch").Preload("Department").Preload("JobPosition").Where("id = ?", id).First(&employee).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &employee, nil
}

func (r *employeeRepository) FindByUserID(userID uuid.UUID) (*domain.Employee, error) {
	var employee domain.Employee
	if err := r.db.Preload("Branch").Preload("User").Preload("Department").Preload("JobPosition").Where("user_id = ?", userID).First(&employee).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &employee, nil
}

func (r *employeeRepository) Update(employee *domain.Employee) error {
	return r.db.Save(employee).Error
}

func (r *employeeRepository) Delete(id uuid.UUID) error {
	return r.db.Where("id = ?", id).Delete(&domain.Employee{}).Error
}

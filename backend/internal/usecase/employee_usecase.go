package usecase

import (
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"golang.org/x/crypto/bcrypt"
)

type EmployeeUsecase interface {
	CreateEmployee(req *CreateEmployeeRequest) error
	GetEmployees(limit int) ([]domain.Employee, error)
	GetEmployeeByID(id uuid.UUID) (*domain.Employee, error)
	GetEmployeeByUserID(userID uuid.UUID) (*domain.Employee, error)
	UpdateEmployee(id uuid.UUID, req *UpdateEmployeeRequest) error
	UpdateProfile(userID uuid.UUID, req *UpdateProfileRequest) error
	DeleteEmployee(id uuid.UUID) error
}

type employeeUsecase struct {
	employeeRepo repository.EmployeeRepository
	userRepo     repository.UserRepository
}

// Request Data Transfer Objects
type CreateEmployeeRequest struct {
	Name              string     `json:"name" binding:"required"`
	Email             string     `json:"email" binding:"required,email"`
	EmployeeIDNumber  string     `json:"employeeIDNumber"`
	BankName          string     `json:"bankName"`
	BankAccountNumber string     `json:"bankAccountNumber"`
	AccountHolderName string     `json:"accountHolderName"`
	Password          string     `json:"password"`
	CompanyID         *uuid.UUID `json:"companyId"`
	BranchID          *uuid.UUID `json:"branchId"`
	DepartmentID      *uuid.UUID `json:"departmentId"`
	JobPositionID     *uuid.UUID `json:"jobPositionId"`
	EmploymentStatus  string     `json:"employmentStatus"`
	JoinDate          string     `json:"joinDate"` // Format: YYYY-MM-DD
	Salary            *float64   `json:"salary"`
	PhoneNumber       string     `json:"phoneNumber"`
}

type UpdateEmployeeRequest struct {
	Name              string     `json:"name" binding:"required"`
	Email             string     `json:"email" binding:"required,email"`
	EmployeeIDNumber  string     `json:"employeeIDNumber"`
	BankName          string     `json:"bankName"`
	BankAccountNumber string     `json:"bankAccountNumber"`
	AccountHolderName string     `json:"accountHolderName"`
	DepartmentID      *uuid.UUID `json:"departmentId"`
	JobPositionID     *uuid.UUID `json:"jobPositionId"`
	BranchID          *uuid.UUID `json:"branchId"`
	EmploymentStatus  string     `json:"employmentStatus"`
	JoinDate          string     `json:"joinDate"`
	Salary            *float64   `json:"salary"`
	PhoneNumber       string     `json:"phoneNumber"`
}

type UpdateProfileRequest struct {
	FirstName          string `json:"firstName"`
	LastName           string `json:"lastName"`
	BirthDate          string `json:"birthDate"` // YYYY-MM-DD
	BirthPlace         string `json:"birthPlace"`
	Gender             string `json:"gender"`
	MaritalStatus      string `json:"maritalStatus"`
	PhoneNumber        string `json:"phoneNumber"`
	AddressKTP         string `json:"addressKTP"`
	AddressResidential string `json:"addressResidential"`
	EmergencyContact   string `json:"emergencyContact"`
	IdentityNumber     string `json:"identityNumber"`
	NpwpNumber         string `json:"npwpNumber"`
	BankName           string `json:"bankName"`
	BankAccountNumber  string `json:"bankAccountNumber"`
	AccountHolderName  string `json:"accountHolderName"`
}

func NewEmployeeUsecase(employeeRepo repository.EmployeeRepository, userRepo repository.UserRepository) EmployeeUsecase {
	return &employeeUsecase{
		employeeRepo: employeeRepo,
		userRepo:     userRepo,
	}
}

func (u *employeeUsecase) CreateEmployee(req *CreateEmployeeRequest) error {
	// Check if user email already exists
	existingUser, _ := u.userRepo.FindByEmail(req.Email)
	if existingUser != nil {
		return errors.New("email already exists")
	}

	// Prepare Default Password if not provided
	password := req.Password
	if password == "" {
		password = "password123"
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return errors.New("failed to hash password")
	}

	// Create User Record
	newUser := &domain.User{
		Email:        req.Email,
		PasswordHash: string(hashedPassword),
		Role:         domain.RoleEmployee,
		IsActive:     true,
	}

	if err := u.userRepo.Create(newUser); err != nil {
		return err
	}

	// Create Associated Employee Record
	empID := req.EmployeeIDNumber
	if empID == "" {
		empID = "EMP-" + uuid.New().String()[:5]
	}

	joinDate := time.Now()
	if req.JoinDate != "" {
		if t, err := time.Parse("2006-01-02", req.JoinDate); err == nil {
			joinDate = t
		}
	}

	newEmployee := &domain.Employee{
		UserID:            newUser.ID,
		FirstName:         req.Name,
		BankName:          req.BankName,
		BankAccountNumber: req.BankAccountNumber,
		AccountHolderName: req.AccountHolderName,
		EmployeeIDNumber:  empID,
		CompanyID:         req.CompanyID,
		BranchID:          req.BranchID,
		DepartmentID:      req.DepartmentID,
		JobPositionID:     req.JobPositionID,
		EmploymentStatus:  req.EmploymentStatus,
		JoinDate:          joinDate,
		Salary:            req.Salary,
		PhoneNumber:       req.PhoneNumber,
	}

	return u.employeeRepo.Create(newEmployee)
}

func (u *employeeUsecase) GetEmployees(limit int) ([]domain.Employee, error) {
	return u.employeeRepo.FindAll(limit)
}

func (u *employeeUsecase) GetEmployeeByID(id uuid.UUID) (*domain.Employee, error) {
	return u.employeeRepo.FindByID(id)
}

func (u *employeeUsecase) GetEmployeeByUserID(userID uuid.UUID) (*domain.Employee, error) {
	return u.employeeRepo.FindByUserID(userID)
}

func (u *employeeUsecase) UpdateEmployee(id uuid.UUID, req *UpdateEmployeeRequest) error {
	employee, err := u.employeeRepo.FindByID(id)
	if err != nil {
		return err
	}
	if employee == nil {
		return errors.New("employee not found")
	}

	// Update Fields
	employee.FirstName = req.Name
	employee.BankName = req.BankName
	employee.BankAccountNumber = req.BankAccountNumber
	employee.AccountHolderName = req.AccountHolderName
	employee.EmployeeIDNumber = req.EmployeeIDNumber
	employee.DepartmentID = req.DepartmentID
	employee.JobPositionID = req.JobPositionID
	employee.BranchID = req.BranchID
	employee.EmploymentStatus = req.EmploymentStatus

	if req.JoinDate != "" {
		if t, err := time.Parse("2006-01-02", req.JoinDate); err == nil {
			employee.JoinDate = t
		}
	}
	
	if req.Salary != nil {
		employee.Salary = req.Salary
	}
	
	employee.PhoneNumber = req.PhoneNumber

	if err := u.employeeRepo.Update(employee); err != nil {
		return err
	}
	return nil
}

func (u *employeeUsecase) UpdateProfile(userID uuid.UUID, req *UpdateProfileRequest) error {
	employee, err := u.employeeRepo.FindByUserID(userID)
	if err != nil {
		return err
	}
	if employee == nil {
		return errors.New("employee not found")
	}

	// Update Fields
	employee.FirstName = req.FirstName
	employee.LastName = req.LastName
	employee.BirthPlace = req.BirthPlace
	employee.Gender = req.Gender
	employee.MaritalStatus = req.MaritalStatus
	employee.PhoneNumber = req.PhoneNumber
	employee.AddressKTP = req.AddressKTP
	employee.AddressResidential = req.AddressResidential
	employee.EmergencyContact = req.EmergencyContact
	employee.IdentityNumber = req.IdentityNumber
	employee.NpwpNumber = req.NpwpNumber
	employee.BankName = req.BankName
	employee.BankAccountNumber = req.BankAccountNumber
	employee.AccountHolderName = req.AccountHolderName

	if req.BirthDate != "" {
		if t, err := time.Parse("2006-01-02", req.BirthDate); err == nil {
			employee.BirthDate = &t
		}
	}

	return u.employeeRepo.Update(employee)
}

func (u *employeeUsecase) DeleteEmployee(id uuid.UUID) error {
	employee, err := u.employeeRepo.FindByID(id)
	if err != nil {
		return err
	}
	if employee == nil {
		return errors.New("employee not found")
	}

	userID := employee.UserID

	// 1. Delete Employee (Cascading deletes related HR data like attendance, payroll, etc. due to DB constraints)
	if err := u.employeeRepo.Delete(id); err != nil {
		return err
	}

	// 2. Delete User account (security clean up)
	if userID != uuid.Nil {
		if err := u.userRepo.Delete(userID); err != nil {
			// We only log if user deletion fails as the main employee data is already gone
			// and this might be an orphaned employee without a user record.
			fmt.Printf("Warning: Failed to delete user record %s for employee %s: %v\n", userID, id, err)
		}
	}

	return nil
}

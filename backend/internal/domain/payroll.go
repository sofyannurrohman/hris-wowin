package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PayrollComponent struct {
	ID        uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	CompanyID *uuid.UUID `gorm:"type:uuid"`
	Name      string     `gorm:"type:varchar(100);not null"`
	Type      string     `gorm:"type:varchar(20);not null"` // EARNING, DEDUCTION, BENEFIT
	IsTaxable bool       `gorm:"default:true"`
	CreatedAt time.Time  `gorm:"default:now()"`

	Company *Company `gorm:"foreignKey:CompanyID"`
}

type MyPayslipResponse struct {
	ID             string              `json:"id"`
	Period         string              `json:"period"`       // "01 Mar - 31 Mar 2026"
	PaymentDate    string              `json:"payment_date"` // YYYY-MM-DD
	JobTitle       string              `json:"job_title"`
	BasicSalary    float64             `json:"basic_salary"`
	TotalAllowance float64             `json:"total_allowance"`
	TotalDeduction float64             `json:"total_deduction"`
	TakeHomePay    float64             `json:"take_home_pay"`
	Earnings       []PayslipItemDetail `json:"earnings"`
	Deductions     []PayslipItemDetail `json:"deductions"`
}

type PayslipItemDetail struct {
	Name   string  `json:"name"`
	Amount float64 `json:"amount"`
}

func (pc *PayrollComponent) BeforeCreate(tx *gorm.DB) (err error) {
	if pc.ID == uuid.Nil {
		pc.ID = uuid.New()
	}
	return
}

type EmployeeSalarySetting struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID  uuid.UUID `gorm:"type:uuid;not null"`
	ComponentID uuid.UUID `gorm:"type:uuid;not null"`
	Amount      float64   `gorm:"type:decimal(15,2);not null"`
	CreatedAt   time.Time `gorm:"default:now()"`

	Employee  *Employee         `gorm:"foreignKey:EmployeeID;constraint:OnDelete:CASCADE;"`
	Component *PayrollComponent `gorm:"foreignKey:ComponentID"`
}

func (ess *EmployeeSalarySetting) BeforeCreate(tx *gorm.DB) (err error) {
	if ess.ID == uuid.Nil {
		ess.ID = uuid.New()
	}
	return
}

type PayrollRun struct {
	ID              uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	CompanyID       *uuid.UUID `gorm:"type:uuid"`
	PeriodStart     time.Time  `gorm:"type:date;not null"`
	PeriodEnd       time.Time  `gorm:"type:date;not null"`
	PaymentSchedule *time.Time `gorm:"type:date"`
	Status          string     `gorm:"type:varchar(20);default:'DRAFT'"`
	TotalPayout     *float64   `gorm:"type:decimal(20,2)"`
	CreatedAt       time.Time  `gorm:"default:now()"`

	Company *Company `gorm:"foreignKey:CompanyID"`
}

func (pr *PayrollRun) BeforeCreate(tx *gorm.DB) (err error) {
	if pr.ID == uuid.Nil {
		pr.ID = uuid.New()
	}
	return
}

type Payslip struct {
	ID                 uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	PayrollRunID       uuid.UUID `gorm:"type:uuid;not null"`
	EmployeeID         uuid.UUID `gorm:"type:uuid;not null"`
	SnapshotJobTitle   string    `gorm:"type:varchar(100)"`
	SnapshotPtkpStatus string    `gorm:"type:varchar(10)"`
	BasicSalary        float64   `gorm:"type:decimal(15,2)"`
	TotalAllowance     float64   `gorm:"type:decimal(15,2)"`
	TotalDeduction     float64   `gorm:"type:decimal(15,2)"`
	TakeHomePay        float64   `gorm:"type:decimal(15,2)"`
	Pph21Amount        float64   `gorm:"type:decimal(15,2)"`
	CreatedAt          time.Time `gorm:"default:now()"`

	PayrollRun *PayrollRun   `gorm:"foreignKey:PayrollRunID"`
	Employee   *Employee     `gorm:"foreignKey:EmployeeID;constraint:OnDelete:CASCADE;"`
	Items      []PayslipItem `gorm:"foreignKey:PayslipID"`
}

func (p *Payslip) BeforeCreate(tx *gorm.DB) (err error) {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return
}

type PayslipItem struct {
	ID            uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	PayslipID     uuid.UUID `gorm:"type:uuid;not null"`
	ComponentName string    `gorm:"type:varchar(100);not null"`
	Amount        float64   `gorm:"type:decimal(15,2);not null"`
	Type          string    `gorm:"type:varchar(20);not null"` // EARNING, DEDUCTION
	CreatedAt     time.Time `gorm:"default:now()"`

	Payslip *Payslip `gorm:"foreignKey:PayslipID"`
}

func (pi *PayslipItem) BeforeCreate(tx *gorm.DB) (err error) {
	if pi.ID == uuid.Nil {
		pi.ID = uuid.New()
	}
	return
}
